// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfMilton.sol";

abstract contract MockCase2Milton is ItfMilton {
    function _getMaxSwapCollateralAmount() internal pure virtual override returns (uint256) {
        return 1e23;
    }

    function _getIncomeFeeRate() internal pure virtual override returns (uint256) {
        return 50000000000000000;
    }

    function _getOpeningFeeRate() internal pure virtual override returns (uint256) {
        return 3e14;
    }

    function _getOpeningFeeTreasuryPortionRate() internal pure virtual override returns (uint256) {
        return 0;
    }

    function _getIporPublicationFee() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }

    function _getLiquidationDepositAmount() internal pure virtual override returns (uint256) {
        return 20;
    }

    function _getMinLeverage() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }

    function _getSafetyIndicators(uint256 liquidityPool)
        internal
        view
        override
        returns (AmmMiltonTypes.OpenSwapSafetyIndicators memory safetyIndicators)
    {
        return AmmMiltonTypes.OpenSwapSafetyIndicators(
            8 * 1e17,
            48 * 1e16,
            48 * 1e16,
            1000 * 1e18,
            1000 * 1e18
        );
    }
}
