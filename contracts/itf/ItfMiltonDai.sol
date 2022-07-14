// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ItfMilton.sol";

contract ItfMiltonDai is ItfMilton {
    function _getDecimals() internal pure override returns (uint256) {
        return 18;
    }

    uint256 internal _max_swap_collateral_amount;
    uint256 internal _max_lp_utilization_rate;
    uint256 internal _max_lp_utilization_per_leg_rate;
    uint256 internal _income_tax_rate;
    uint256 internal _opening_fee_rate;
    uint256 internal _opening_fee_for_treasury_portion_rate;
    uint256 internal _ipor_publication_fee;
    uint256 internal _liquidation_deposit_amount;
    uint256 internal _max_leverage;
    uint256 internal _min_leverage;
    uint256 internal _min_liquidation_threshold_to_close_before_maturity;
    uint256 internal _secondsBeforeMaturityWhenPositionCanBeClosed;
    uint256 internal _liquidationLegLimit;

    function _getMaxSwapCollateralAmount() internal pure override returns (uint256) {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function _getMaxLpUtilizationRate() internal pure override returns (uint256) {
        return _MAX_LP_UTILIZATION_RATE;
    }

    function _getMaxLpUtilizationPerLegRate() internal pure override returns (uint256) {
        return _MAX_LP_UTILIZATION_PER_LEG_RATE;
    }

    function _getIncomeFeeRate() internal pure override returns (uint256) {
        return _INCOME_TAX_RATE;
    }

    function _getOpeningFeeRate() internal pure override returns (uint256) {
        return _OPENING_FEE_RATE;
    }

    function _getOpeningFeeTreasuryPortionRate() internal pure override returns (uint256) {
        return _OPENING_FEE_FOR_TREASURY_PORTION_RATE;
    }

    function _getIporPublicationFee() internal pure override returns (uint256) {
        return _IPOR_PUBLICATION_FEE;
    }

    function _getLiquidationDepositAmount() internal pure override returns (uint256) {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function _getMaxLeverage() internal pure override returns (uint256) {
        return _MAX_LEVERAGE;
    }

    function _getMinLeverage() internal pure override returns (uint256) {
        return _MIN_LEVERAGE;
    }

    function _getMinLiquidationThresholdToCloseBeforeMaturity()
        internal
        pure
        override
        returns (uint256)
    {
        return _MIN_LIQUIDATION_THRESHOLD_TO_CLOSE_BEFORE_MATURITY;
    }

    function _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        internal
        pure
        override
        returns (uint256)
    {
        return _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED;
    }

    function _getLiquidationLegLimit() internal pure override returns (uint256) {
        return _LIQUIDATION_LEG_LIMIT;
    }
}
