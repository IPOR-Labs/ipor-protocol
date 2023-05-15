// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfMilton.sol";

abstract contract MockCase2Milton is ItfMilton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) ItfMilton(iporRiskManagementOracle) {
    }

    function _getMaxSwapCollateralAmount() internal pure virtual override returns (uint256) {
        return 1e23;
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
}
