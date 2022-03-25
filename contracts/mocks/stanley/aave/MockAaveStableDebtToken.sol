// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

contract MockAaveStableDebtToken {
    uint256 private _totalStableDebt;
    uint256 private _avgStableRate;

    constructor(uint256 debt, uint256 rate) {
        _totalStableDebt = debt;
        _avgStableRate = rate;
    }

    function getTotalSupplyAndAvgRate() external view returns (uint256, uint256) {
        return (_totalStableDebt, _avgStableRate);
    }
}
