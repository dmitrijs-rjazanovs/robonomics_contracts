pragma solidity ^0.4.2;

import 'cashflow/CrowdSale.sol';

library CreatorCrowdSale {
    function create(address _target, address _credits, address _sale, uint256 _start_time_sec, uint256 _duration_sec, uint256 _start_price, uint256 _step, uint256 _period_sec, uint256 _min_value, uint256 _end_value) returns (CrowdSale)
    { return new CrowdSale(_target, _credits, _sale, _start_time_sec, _duration_sec, _start_price, _step, _period_sec, _min_value, _end_value); }

    function version() constant returns (string)
    { return "v0.4.9 (b6490d28)"; }

    function abi() constant returns (string)
    { return '[{"constant":true,"inputs":[],"name":"currentPeriod","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"end_time","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"endValue","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"is_alive","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"creditsOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"credits","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"is_fail","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"deal","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"delegate","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"sale","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"start_time","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"priceStep","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minValue","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"currentPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"stepPeriod","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"target","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_target","type":"address"},{"name":"_credits","type":"address"},{"name":"_sale","type":"address"},{"name":"_start_time_sec","type":"uint256"},{"name":"_duration_sec","type":"uint256"},{"name":"_start_price","type":"uint256"},{"name":"_step","type":"uint256"},{"name":"_period_sec","type":"uint256"},{"name":"_min_value","type":"uint256"},{"name":"_end_value","type":"uint256"}],"type":"constructor"},{"anonymous":false,"inputs":[],"name":"Failed","type":"event"},{"anonymous":false,"inputs":[],"name":"Start","type":"event"},{"anonymous":false,"inputs":[],"name":"Finish","type":"event"}]'; }
}
