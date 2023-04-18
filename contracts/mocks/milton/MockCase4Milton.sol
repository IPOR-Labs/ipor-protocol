// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfMilton.sol";

abstract contract MockCase4Milton is ItfMilton {
    function _getMaxSwapCollateralAmount() internal pure virtual override returns (uint256) {
        return 1e23;
    }

    function _getMaxLpUtilizationRate() internal pure virtual override returns (uint256) {
        return 8 * 1e17;
    }

    function _getMaxLpUtilizationPerLegRate() internal pure virtual override returns (uint256) {
        return 48 * 1e18;
    }

    function _getOpeningFeeRate() internal pure virtual override returns (uint256) {
        return 3e14;
    }

    function _getOpeningFeeTreasuryPortionRate() internal pure virtual override returns (uint256) {
        return 50000000000000000;
    }

    function _getIporPublicationFee() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }

    function _getLiquidationDepositAmount() internal pure virtual override returns (uint256) {
        return 20;
    }

    function _getMaxLeverage() internal pure virtual override returns (uint256) {
        return 1000 * 1e18;
    }

    function _getMinLeverage() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }
}
