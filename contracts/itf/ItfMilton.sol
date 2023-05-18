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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) Milton(iporRiskManagementOracle) {}

    function getVersion() external pure virtual override returns (uint256) {
        return 7;
    }

    //    function itfOpenSwapPayFixed(
    //        uint256 openTimestamp,
    //        uint256 totalAmount,
    //        uint256 acceptableFixedInterestRate,
    //        uint256 leverage
    //    ) external returns (uint256) {
    //        return _openSwapPayFixed(openTimestamp, totalAmount, acceptableFixedInterestRate, leverage);
    //    }
    //
    //    function itfOpenSwapReceiveFixed(
    //        uint256 openTimestamp,
    //        uint256 totalAmount,
    //        uint256 acceptableFixedInterestRate,
    //        uint256 leverage
    //    ) external returns (uint256) {
    //        return
    //            _openSwapReceiveFixed(
    //                openTimestamp,
    //                totalAmount,
    //                acceptableFixedInterestRate,
    //                leverage
    //            );
    //    }

    function itfCloseSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        uint256 closeTimestamp
    )
        external
        nonReentrant
        whenNotPaused
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            closeTimestamp
        );
    }

    function itfCloseSwapPayFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, closeTimestamp);
    }

    function itfCloseSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, closeTimestamp);
    }

    function itfCloseSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(swapIds, closeTimestamp);
    }

    function itfCloseSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(swapIds, closeTimestamp);
    }

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

    function itfCalculatePayoff(
        IporTypes.IporSwapMemory memory iporSwap,
        MiltonTypes.SwapDirection direction,
        uint256 closeTimestamp,
        int256 basePayoff,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory balance
    ) external returns (int256 payoff) {
        payoff = _calculatePayoff(iporSwap, direction, closeTimestamp, basePayoff, accruedIpor, balance);
    }

    function _itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId) internal view returns (int256) {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, calculateTimestamp);
        return swap.calculatePayoffPayFixed(calculateTimestamp, accruedIbtPrice);
    }

    function _itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, calculateTimestamp);
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

    function _getMinLiquidationThresholdToCloseBeforeMaturityByBuyer()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (_minLiquidationThresholdToCloseBeforeMaturity != 0) {
            return _minLiquidationThresholdToCloseBeforeMaturity;
        }
        return 99 * 1e16;
    }

    function _getSecondsBeforeMaturityWhenPositionCanBeClosed() internal view virtual override returns (uint256) {
        if (_secondsBeforeMaturityWhenPositionCanBeClosed != 0) {
            return _secondsBeforeMaturityWhenPositionCanBeClosed;
        }
        return _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED;
    }

    function _getLiquidationLegLimit() internal view virtual override returns (uint256) {
        if (_liquidationLegLimit != 0) {
            return _liquidationLegLimit;
        }
        return _LIQUIDATION_LEG_LIMIT;
    }
}
