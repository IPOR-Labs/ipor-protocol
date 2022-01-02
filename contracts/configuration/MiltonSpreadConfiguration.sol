// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "../libraries/Constants.sol";
import "../libraries/AmmMath.sol";
import "../interfaces/IMiltonSpreadConfiguration.sol";
import "./AccessControlMiltonSpreadConfiguration.sol";

contract MiltonSpreadConfiguration is
    AccessControlMiltonSpreadConfiguration(msg.sender),
    IMiltonSpreadConfiguration
{

	address private immutable _asset;
	
    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint256 internal _spreadDemandComponentKfValue;

    //@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint256 internal _spreadDemandComponentLambdaValue;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint256 internal _spreadDemandComponentKOmegaValue;

    //@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint256 internal _spreadDemandComponentMaxLiquidityRedemptionValue;

    //@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint256 internal _spreadAtParComponentKVolValue;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint256 internal _spreadAtParComponentKHistValue;

    //@notice Spread Max Value
    uint256 internal _spreadMaxValue;

    constructor(address asset) {
		_asset = asset;
        _spreadDemandComponentKfValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        _spreadDemandComponentLambdaValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        _spreadDemandComponentKOmegaValue = AmmMath.division(
            3 * Constants.D18,
            10
        );

        _spreadDemandComponentMaxLiquidityRedemptionValue = Constants.D18;

        //TODO: clarify initial value
        _spreadAtParComponentKVolValue = AmmMath.division(
            3 * Constants.D18,
            100
        );

        //TODO: clarify initial value
        _spreadAtParComponentKHistValue = AmmMath.division(
            3 * Constants.D18,
            100
        );

        _spreadMaxValue = AmmMath.division(3 * Constants.D18, 10);
    }

    function getSpreadDemandComponentKfValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentKfValue;
    }

    function setSpreadDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE) {
        _spreadDemandComponentKfValue = newSpreadDemandComponentKfValue;
        emit SpreadDemandComponentKfValueSet(newSpreadDemandComponentKfValue);
    }

    function getSpreadDemandComponentLambdaValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentLambdaValue;
    }

    function setSpreadDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE) {
        _spreadDemandComponentLambdaValue = newSpreadDemandComponentLambdaValue;
        emit SpreadDemandComponentLambdaValueSet(
            newSpreadDemandComponentLambdaValue
        );
    }

    function getSpreadDemandComponentKOmegaValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentKOmegaValue;
    }

    function setSpreadDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE) {
        _spreadDemandComponentKOmegaValue = newSpreadDemandComponentKOmegaValue;
        emit SpreadDemandComponentKOmegaValueSet(
            newSpreadDemandComponentKOmegaValue
        );
    }

    function getSpreadDemandComponentMaxLiquidityRedemptionValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentMaxLiquidityRedemptionValue;
    }

    function setSpreadDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    )
        external
        override
        onlyRole(_SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE)
    {
        _spreadDemandComponentMaxLiquidityRedemptionValue = newSpreadDemandComponentMaxLiquidityRedemptionValue;
        emit SpreadDemandComponentMaxLiquidityRedemptionValueSet(
            newSpreadDemandComponentMaxLiquidityRedemptionValue
        );
    }

    function getSpreadAtParComponentKVolValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadAtParComponentKVolValue;
    }

    function setSpreadAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE) {
        _spreadAtParComponentKVolValue = newSpreadAtParComponentKVolValue;
        emit SpreadAtParComponentKVolValueSet(newSpreadAtParComponentKVolValue);
    }

    function getSpreadAtParComponentKHistValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadAtParComponentKHistValue;
    }

    function setSpreadAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE) {
        _spreadAtParComponentKHistValue = newSpreadAtParComponentKHistValue;
        emit SpreadAtParComponentKHistValueSet(
            newSpreadAtParComponentKHistValue
        );
    }

    function getSpreadMaxValue() external view override returns (uint256) {
        return _spreadMaxValue;
    }

    function setSpreadMaxValue(uint256 newSpreadMaxValue)
        external
        override
        onlyRole(_SPREAD_MAX_VALUE_ROLE)
    {
        _spreadMaxValue = newSpreadMaxValue;
        emit SpreadMaxValueSet(newSpreadMaxValue);
    }
}
