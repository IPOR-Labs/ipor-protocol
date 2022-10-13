// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";

contract MockSpreadModel is IMiltonSpreadModel {
    uint256 private _calculateQuotePayFixed;
    uint256 private _calculateQuoteReceiveFixed;
    int256 private _calculateSpreadPayFixed;
    int256 private _calculateSpreadReceiveFixed;

    constructor(
        uint256 calculateQuotePayFixedValue,
        uint256 calculateQuoteReceiveFixedValue,
        int256 calculateSpreadPayFixedValue,
        int256 calculateSpreadReceiveFixedVaule
    ) {
        _calculateQuotePayFixed = calculateQuotePayFixedValue;
        _calculateQuoteReceiveFixed = calculateQuoteReceiveFixedValue;
        _calculateSpreadPayFixed = calculateSpreadPayFixedValue;
        _calculateSpreadReceiveFixed = calculateSpreadReceiveFixedVaule;
    }

    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        return _calculateQuotePayFixed;
    }

    function setCalculateQuotePayFixed(uint256 value) external {
        _calculateQuotePayFixed = value;
    }

    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        quoteValue = _calculateQuoteReceiveFixed;
    }

    function setCalculateQuoteReceiveFixed(uint256 value) external {
        _calculateQuoteReceiveFixed = value;
    }

    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPayFixed;
    }

    function setCalculateSpreadPayFixed(int256 value) external {
        _calculateSpreadPayFixed = value;
    }

    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        spreadValue = _calculateSpreadReceiveFixed;
    }

    function setCalculateSpreadReceiveFixed(int256 value) external {
        _calculateSpreadReceiveFixed = value;
    }
}
