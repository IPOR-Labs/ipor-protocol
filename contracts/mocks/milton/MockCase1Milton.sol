// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../itf/ItfMilton.sol";

contract MockCase1Milton is ItfMilton {
    function _getMaxSwapCollateralAmount() internal pure virtual override returns (uint256) {
        return 1e23;
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

    function _getIncomeTaxPercentage() internal pure virtual override returns (uint256) {
        return 1e17;
    }

    function _getOpeningFeePercentage() internal pure virtual override returns (uint256) {
        return 600000000000000000;
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

    function _getMaxCollateralizationFactorValue()
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return 1000 * 1e18;
    }

    function _getMinCollateralizationFactorValue()
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return 10 * 1e18;
    }
}
