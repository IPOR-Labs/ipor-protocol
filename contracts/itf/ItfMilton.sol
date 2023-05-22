// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../amm/Milton.sol";
import "./types/ItfMiltonTypes.sol";

abstract contract ItfMilton is Milton {
    using SafeCast for uint256;

    uint256 internal _maxSwapCollateralAmount;
    uint256 internal _maxLpUtilizationRate;
    uint256 internal _maxLpUtilizationPerLegRate;
    uint256 internal _openingFeeRate;
    uint256 internal _openingFeeForTreasuryPortionRate;
    uint256 internal _iporPublicationFee;
    uint256 internal _liquidationDepositAmount;
    uint256 internal _maxLeverage;
    uint256 internal _minLeverage;
    uint256 internal _minLiquidationThresholdToCloseBeforeMaturity;
    uint256 internal _secondsBeforeMaturityWhenPositionCanBeClosed;
    uint256 internal _liquidationLegLimit;

    constructor(
        address asset,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address router
    ) Milton(asset, decimals, ammStorage, assetManagement, router) {}

    function setMiltonConstants(
        uint256 maxSwapCollateralAmount,
        uint256 liquidationDepositAmount,
        uint256 minLiquidationThresholdToCloseBeforeMaturity,
        uint256 secondsBeforeMaturityWhenPositionCanBeClosed,
        uint256 liquidationLegLimit,
        ItfMiltonTypes.ItfUtilization memory utilization,
        ItfMiltonTypes.ItfFees memory fees,
        ItfMiltonTypes.ItfLeverage memory leverage
    ) external {
        _maxSwapCollateralAmount = maxSwapCollateralAmount;
        _maxLpUtilizationRate = utilization.maxLpUtilizationRate;
        _maxLpUtilizationPerLegRate = utilization.maxLpUtilizationPerLegRate;
        _openingFeeRate = fees.openingFeeRate;
        _openingFeeForTreasuryPortionRate = fees.openingFeeForTreasuryPortionRate;
        _iporPublicationFee = fees.iporPublicationFee;
        _liquidationDepositAmount = liquidationDepositAmount;
        _maxLeverage = leverage.maxLeverage;
        _minLeverage = leverage.minLeverage;
        _minLiquidationThresholdToCloseBeforeMaturity = minLiquidationThresholdToCloseBeforeMaturity;
        _secondsBeforeMaturityWhenPositionCanBeClosed = secondsBeforeMaturityWhenPositionCanBeClosed;
        _liquidationLegLimit = liquidationLegLimit;
    }
}
