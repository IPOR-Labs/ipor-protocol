// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../itf/ItfMilton.sol";

abstract contract MockCase2Milton is ItfMilton {
    function _getMaxSwapCollateralAmount() internal pure virtual override returns (uint256) {
        return 1e23;
    }

    function _getMaxSlippagePercentage() internal pure virtual override returns (uint256) {
        return 1e18;
    }

    function _getMaxLpUtilizationPercentage() internal pure virtual override returns (uint256) {
        return 8 * 1e17;
    }

    function _getMaxLpUtilizationPerLegPercentage()
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return 48 * 1e18;
    }

    function _getIncomeFeePercentage() internal pure virtual override returns (uint256) {
        return 50000000000000000;
    }

    function _getOpeningFeePercentage() internal pure virtual override returns (uint256) {
        return 3e14;
    }

    function _getOpeningFeeForTreasuryPercentage()
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function _getIporPublicationFeeAmount() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }

    function _getLiquidationDepositAmount() internal pure virtual override returns (uint256) {
        return 20 * 1e18;
    }

    function _getMaxLeverageValue() internal pure virtual override returns (uint256) {
        return 1000 * 1e18;
    }

    function _getMinLeverageValue() internal pure virtual override returns (uint256) {
        return 10 * 1e18;
    }
}
