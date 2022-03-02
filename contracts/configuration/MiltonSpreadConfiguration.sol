// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IMiltonSpreadConfiguration.sol";

contract MiltonSpreadConfiguration is IMiltonSpreadConfiguration {
    //@notice Spread Premiums Max Value
    uint256 internal constant _SPREAD_PREMIUMS_MAX_VALUE = 3e15;

    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint256 internal constant _DC_KF_VALUE = 1e13;

    //@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint256 internal constant _DC_LAMBDA_VALUE = 1e16;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint256 internal constant _DC_K_OMEGA_VALUE = 5e13;

    //@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint256 internal constant _DC_MAX_LIQUIDITY_REDEMPTION_VALUE = 1e18;

    //@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint256 internal constant _AT_PAR_COMPONENT_K_VOL_VALUE = 0;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint256 internal constant _AT_PAR_COMPONENT_K_HIST_VALUE = 3e14;

    function getSpreadPremiumsMaxValue() external pure override returns (uint256) {
        return _SPREAD_PREMIUMS_MAX_VALUE;
    }

    function getDCKfValue() external pure override returns (uint256) {
        return _DC_KF_VALUE;
    }

    function getDCLambdaValue() external pure override returns (uint256) {
        return _DC_LAMBDA_VALUE;
    }

    function getDCKOmegaValue() external pure override returns (uint256) {
        return _DC_K_OMEGA_VALUE;
    }

    function getDCMaxLiquidityRedemptionValue()
        external
        pure
        override
        returns (uint256)
    {
        return _DC_MAX_LIQUIDITY_REDEMPTION_VALUE;
    }

    function getAtParComponentKVolValue()
        external
        pure
        override
        returns (uint256)
    {
        return _AT_PAR_COMPONENT_K_VOL_VALUE;
    }

    function getAtParComponentKHistValue()
        external
        pure
        override
        returns (uint256)
    {
        return _AT_PAR_COMPONENT_K_HIST_VALUE;
    }

    function _getSpreadPremiumsMaxValue() internal pure virtual returns (uint256) {
        return _SPREAD_PREMIUMS_MAX_VALUE;
    }

    function _getDCKfValue() internal pure virtual returns (uint256) {
        return _DC_KF_VALUE;
    }

    function _getDCLambdaValue() internal pure virtual returns (uint256) {
        return _DC_LAMBDA_VALUE;
    }

    function _getDCKOmegaValue() internal pure virtual returns (uint256) {
        return _DC_K_OMEGA_VALUE;
    }

    function _getDCMaxLiquidityRedemptionValue()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _DC_MAX_LIQUIDITY_REDEMPTION_VALUE;
    }

    function _getAtParComponentKVolValue()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _AT_PAR_COMPONENT_K_VOL_VALUE;
    }

    function _getAtParComponentKHistValue()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _AT_PAR_COMPONENT_K_HIST_VALUE;
    }
}
