// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../amm/Milton.sol";
import "./types/ItfMiltonTypes.sol";

abstract contract ItfMilton is Milton {
    using SafeCast for uint256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

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

    function itfCalculateSoap(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (soapPayFixed, soapReceiveFixed, soap) = _calculateSoap(calculateTimestamp);
    }

    function itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId) external view returns (int256) {
        return _itfCalculateSwapPayFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        return _itfCalculateSwapReceiveFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculatePayoffForSwaps(
        uint256 calculateTimestamp,
        uint256[] memory swapIdsPayFixed,
        uint256[] memory swapIdsReceiveFixed
    ) external view returns (int256 plnValue, int256 payoffGross) {
        for (uint256 i = 0; i != swapIdsPayFixed.length; i++) {
            int256 payoff = _itfCalculateSwapPayFixedValue(calculateTimestamp, swapIdsPayFixed[i]);
            payoffGross += payoff;
        }
        for (uint256 j = 0; j != swapIdsReceiveFixed.length; j++) {
            int256 payoff = _itfCalculateSwapReceiveFixedValue(calculateTimestamp, swapIdsReceiveFixed[j]);
            payoffGross += payoff;
        }
    }

    function _itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId) internal view returns (int256) {
        IporTypes.IporSwapMemory memory swap = IMiltonStorage(_ammStorage).getSwapPayFixed(swapId);
        uint256 accruedIbtPrice = IIporOracle(iporOracleDeprecated).calculateAccruedIbtPrice(_asset, calculateTimestamp);
        return swap.calculatePayoffPayFixed(calculateTimestamp, accruedIbtPrice);
    }

    function _itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = IMiltonStorage(_ammStorage).getSwapReceiveFixed(swapId);
        uint256 accruedIbtPrice = IIporOracle(iporOracleDeprecated).calculateAccruedIbtPrice(_asset, calculateTimestamp);
        return swap.calculatePayoffReceiveFixed(calculateTimestamp, accruedIbtPrice);
    }

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
