pragma solidity ^0.4.24;

import './RobotLiability.sol';
import './SingletonHash.sol';
import './DutchAuction.sol';
import './Lighthouse.sol';
import './XRT.sol';

import 'ens/contracts/ENS.sol';
import 'ens/contracts/AbstractENS.sol';
import 'ens/contracts/PublicResolver.sol';

import 'openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol';

contract LiabilityFactory is SingletonHash {
    constructor(
        address _robot_liability_lib,
        address _lighthouse_lib,
        DutchAuction _auction,
        XRT _xrt,
        ENS _ens
    ) public {
        robotLiabilityLib = _robot_liability_lib;
        lighthouseLib = _lighthouse_lib;
        auction = _auction;
        xrt = _xrt;
        ens = _ens;
    }

    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;

    /**
     * @dev New liability created 
     */
    event NewLiability(address indexed liability);

    /**
     * @dev New lighthouse created
     */
    event NewLighthouse(address indexed lighthouse, string name);

    /**
     * @dev Robonomics dutch auction contract
     */
    DutchAuction public auction;

    /**
     * @dev Robonomics network protocol token
     */
    XRT public xrt;

    /**
     * @dev Ethereum name system
     */
    ENS public ens;

    /**
     * @dev Total GAS utilized by Robonomics network
     */
    uint256 public totalGasUtilizing = 0;

    /**
     * @dev GAS utilized by liability contracts
     */
    mapping(address => uint256) public gasUtilizing;

    /**
     * @dev The count of utilized gas for switch to next epoch 
     */
    uint256 public constant gasEpoch = 347 * 10**10;

    /**
     * @dev SMMA filter with function: SMMA(i) = (SMMA(i-1)*(n-1) + PRICE(i)) / n
     * @param _prePrice PRICE[n-1]
     * @param _price PRICE[n]
     * @return filtered price
     */
    function smma(uint256 _prePrice, uint256 _price) internal returns (uint256) {
        return (_prePrice * (smmaPeriod - 1) + _price) / smmaPeriod;
    }

    /**
     * @dev SMMA filter period
     */
    uint256 public constant smmaPeriod = 100;

    /**
     * @dev Current gas price in wei
     */
    uint256 public gasPrice = 10 * 10**9;

    /**
     * @dev Lighthouse accounting
     */
    mapping(address => bool) public isLighthouse;

    /**
     * @dev Robot liability shared code smart contract
     */
    address public robotLiabilityLib;

    /**
     * @dev Lightouse shared code smart contract
     */
    address public lighthouseLib;

    /**
     * @dev XRT emission value for utilized gas
     */
    function wnFromGas(uint256 _gas) view returns (uint256) {
        // Just return wn=gas when auction isn't finish
        if (auction.finalPrice() == 0)
            return _gas;

        // Current gas utilization epoch
        uint256 epoch = totalGasUtilizing / gasEpoch;

        // XRT emission with addition coefficient by gas utilzation epoch
        uint256 wn = _gas * 10**9 * gasPrice * 2**epoch / 3**epoch / auction.finalPrice();

        // Check to not permit emission decrease below wn=gas
        return wn < _gas ? _gas : wn;
    }

    /**
     * @dev Only lighthouse guard
     */
    modifier onlyLighthouse {
        require(isLighthouse[msg.sender]);
        _;
    }

    modifier gasPriceEstimated {
        gasPrice = smma(gasPrice, tx.gasprice);
        _;
    }


    /**
     * @dev Create robot liability smart contract
     * @param _demand ABI-encoded demand message 
     * @param _offer ABI-encoded offer message 
     */
    function createLiability(
        bytes _demand,
        bytes _offer
    )
        external 
        onlyLighthouse
        gasPriceEstimated
        returns (RobotLiability liability) { // Store in memory available gas
        uint256 gasinit = gasleft();

        // Create liability
        liability = new RobotLiability(robotLiabilityLib);
        emit NewLiability(liability);

        // Parse messages
        require(liability.call(abi.encodePacked(bytes4(0xd9ff764a), _demand))); // liability.demand(...)
        singletonHash(liability.demandHash());

        require(liability.call(abi.encodePacked(bytes4(0xd5056962), _offer))); // liability.offer(...)
        singletonHash(liability.offerHash());

        // Transfer lighthouse fee to lighthouse worker directly
        if (liability.lighthouseFee() > 0)
            xrt.safeTransferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee());

        // Transfer liability security and hold on contract
        ERC20 token = liability.token();
        if (liability.cost() > 0)
            token.safeTransferFrom(liability.promisee(),
                                   liability,
                                   liability.cost());

        // Transfer validator fee and hold on contract
        if (address(liability.validator()) != 0 && liability.validatorFee() > 0)
            xrt.safeTransferFrom(liability.promisee(),
                                 liability,
                                 liability.validatorFee());

        // Accounting gas usage of transaction
        uint256 gas = gasinit - gasleft() + 110525; // Including observation error
        totalGasUtilizing       += gas;
        gasUtilizing[liability] += gas;
     }

    /**
     * @dev Create lighthouse smart contract
     * @param _minimalFreeze Minimal freeze value of XRT token
     * @param _timeoutBlocks Max time of lighthouse silence in blocks
     * @param _name Lighthouse subdomain,
     *              example: for 'my-name' will created 'my-name.lighthouse.1.robonomics.eth' domain
     */
    function createLighthouse(
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks,
        string  _name
    )
        external
        returns (address lighthouse)
    {
        bytes32 lighthouseNode
            // lighthouse.3.robonomics.eth
            = 0x87bd923a85f096b00a4a347fb56cef68e95319b3d9dae1dff59259db094afd02;

        // Name reservation check
        bytes32 subnode = keccak256(abi.encodePacked(lighthouseNode, keccak256(_name)));
        require(ens.resolver(subnode) == 0);

        // Create lighthouse
        lighthouse = new Lighthouse(lighthouseLib, _minimalFreeze, _timeoutBlocks);
        emit NewLighthouse(lighthouse, _name);
        isLighthouse[lighthouse] = true;

        // Register subnode
        ens.setSubnodeOwner(lighthouseNode, keccak256(_name), this);

        // Register lighthouse address
        PublicResolver resolver = PublicResolver(ens.resolver(lighthouseNode));
        ens.setResolver(subnode, resolver);
        resolver.setAddr(subnode, lighthouse);
    }

    /**
     * @dev Is called whan after liability finalization
     * @param _gas Liability finalization gas expenses
     */
    function liabilityFinalized(
        uint256 _gas
    )
        external
        gasPriceEstimated
        returns (bool)
    {
        require(gasUtilizing[msg.sender] > 0);

        uint256 gas = _gas - gasleft();
        require(_gas > gas);

        totalGasUtilizing        += gas;
        gasUtilizing[msg.sender] += gas;

        require(xrt.mint(tx.origin, wnFromGas(gasUtilizing[msg.sender])));
        return true;
    }
}
