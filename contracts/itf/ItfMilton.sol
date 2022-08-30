// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../amm/Milton.sol";
import "./types/ItfMiltonTypes.sol";

abstract contract ItfMilton is Milton {
    using SafeCast for uint256;

    uint256 internal _maxSwapCollateralAmount;
    uint256 internal _maxLpUtilizationRate;
    uint256 internal _maxLpUtilizationPerLegRate;
    uint256 internal _incomeTaxRate;
    uint256 internal _openingFeeRate;
    uint256 internal _openingFeeForTreasuryPortionRate;
    uint256 internal _iporPublicationFee;
    uint256 internal _liquidationDepositAmount;
    uint256 internal _maxLeverage;
    uint256 internal _minLeverage;
    uint256 internal _minLiquidationThresholdToCloseBeforeMaturity;
    uint256 internal _secondsBeforeMaturityWhenPositionCanBeClosed;
    uint256 internal _liquidationLegLimit;

    function itfOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256) {
        return _openSwapPayFixed(openTimestamp, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function itfOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256) {
        return
            _openSwapReceiveFixed(
                openTimestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            );
    }

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
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
            swapIds,
            closeTimestamp
        );
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

    function itfCalculateSpread(uint256 calculateTimestamp)
        external
        view
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        (spreadPayFixed, spreadReceiveFixed) = _calculateSpread(calculateTimestamp);
    }

    function itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        return _itfCalculateSwapPayFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        return _itfCalculateSwapReceiveFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculateIncomeFeeValue(int256 payoff) external view returns (uint256) {
        return _calculateIncomeFeeValue(payoff);
    }

    function itfCalculatePnlForSwaps(
        uint256 calculateTimestamp,
        uint256[] memory swapIdsPayFixed,
        uint256[] memory swapIdsReceiveFixed
    ) external view returns (int256 plnValue, int256 payoffGross) {
        for (uint256 i = 0; i != swapIdsPayFixed.length; i++) {
            int256 payoff = _itfCalculateSwapPayFixedValue(calculateTimestamp, swapIdsPayFixed[i]);
            payoffGross += payoff;
            plnValue += _itfSubstractIncomeFeeValue(payoff);
        }
        for (uint256 j = 0; j != swapIdsReceiveFixed.length; j++) {
            int256 payoff = _itfCalculateSwapReceiveFixedValue(
                calculateTimestamp,
                swapIdsReceiveFixed[j]
            );
            payoffGross += payoff;
            plnValue += _itfSubstractIncomeFeeValue(payoff);
        }
    }

    function _itfSubstractIncomeFeeValue(int256 payoff) internal view returns (int256) {
        if (payoff <= 0) {
            return payoff;
        }
        return payoff - _calculateIncomeFeeValue(payoff).toInt256();
    }

    function _itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        return _calculatePayoffPayFixed(calculateTimestamp, swap);
    }

    function _itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        return _calculatePayoffReceiveFixed(calculateTimestamp, swap);
    }

    function setMiltonConstants(
        uint256 maxSwapCollateralAmount,
        uint256 incomeTaxRate,
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
        _incomeTaxRate = incomeTaxRate;
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

    function _getMaxSwapCollateralAmount() internal view virtual override returns (uint256) {
        if (_maxSwapCollateralAmount != 0) {
            return _maxSwapCollateralAmount;
        }
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function _getMaxLpUtilizationRate() internal view virtual override returns (uint256) {
        if (_maxLpUtilizationRate != 0) {
            return _maxLpUtilizationRate;
        }
        return _MAX_LP_UTILIZATION_RATE;
    }

    function _getMaxLpUtilizationPerLegRate() internal view virtual override returns (uint256) {
        if (_maxLpUtilizationPerLegRate != 0) {
            return _maxLpUtilizationPerLegRate;
        }
        return _MAX_LP_UTILIZATION_PER_LEG_RATE;
    }

    function _getIncomeFeeRate() internal view virtual override returns (uint256) {
        if (_incomeTaxRate != 0) {
            return _incomeTaxRate;
        }
        return _INCOME_TAX_RATE;
    }

    function _getOpeningFeeRate() internal view virtual override returns (uint256) {
        if (_openingFeeRate != 0) {
            return _openingFeeRate;
        }
        return _OPENING_FEE_RATE;
    }

    function _getOpeningFeeTreasuryPortionRate() internal view virtual override returns (uint256) {
        if (_openingFeeForTreasuryPortionRate != 0) {
            return _openingFeeForTreasuryPortionRate;
        }
        return _OPENING_FEE_FOR_TREASURY_PORTION_RATE;
    }

    function _getIporPublicationFee() internal view virtual override returns (uint256) {
        if (_iporPublicationFee != 0) {
            return _iporPublicationFee;
        }
        return _IPOR_PUBLICATION_FEE;
    }

    function _getLiquidationDepositAmount() internal view virtual override returns (uint256) {
        if (_liquidationDepositAmount != 0) {
            return _liquidationDepositAmount;
        }
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function _getMaxLeverage() internal view virtual override returns (uint256) {
        if (_maxLeverage != 0) {
            return _maxLeverage;
        }
        return _MAX_LEVERAGE;
    }

    function _getMinLeverage() internal view virtual override returns (uint256) {
        if (_minLeverage != 0) {
            return _minLeverage;
        }
        return _MIN_LEVERAGE;
    }

    function _getMinLiquidationThresholdToCloseBeforeMaturity()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (_minLiquidationThresholdToCloseBeforeMaturity != 0) {
            return _minLiquidationThresholdToCloseBeforeMaturity;
        }
        return _MIN_LIQUIDATION_THRESHOLD_TO_CLOSE_BEFORE_MATURITY;
    }

    function _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        internal
        view
        virtual
        override
        returns (uint256)
    {
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
