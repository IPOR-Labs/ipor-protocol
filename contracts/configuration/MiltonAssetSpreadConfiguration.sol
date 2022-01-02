// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "../libraries/Constants.sol";
import "../libraries/AmmMath.sol";
import "../interfaces/IMiltonAssetSpreadConfiguration.sol";
import "./AccessControlMiltonAssetSpreadConfiguration.sol";

contract MiltonAssetSpreadConfiguration is
    AccessControlMiltonAssetSpreadConfiguration(msg.sender),
    IMiltonAssetSpreadConfiguration
{

	address private immutable _asset;
	
    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint256 internal _demandComponentKfValue;

    //@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint256 internal _demandComponentLambdaValue;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint256 internal _demandComponentKOmegaValue;

    //@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint256 internal _demandComponentMaxLiquidityRedemptionValue;

    //@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint256 internal _atParComponentKVolValue;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint256 internal _atParComponentKHistValue;

    //@notice Spread Max Value
    uint256 internal _maxValue;

    constructor(address asset) {
		_asset = asset;
        _demandComponentKfValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        _demandComponentLambdaValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        _demandComponentKOmegaValue = AmmMath.division(
            3 * Constants.D18,
            10
        );

        _demandComponentMaxLiquidityRedemptionValue = Constants.D18;

        //TODO: clarify initial value
        _atParComponentKVolValue = AmmMath.division(
            3 * Constants.D18,
            100
        );

        //TODO: clarify initial value
        _atParComponentKHistValue = AmmMath.division(
            3 * Constants.D18,
            100
        );

        _maxValue = AmmMath.division(3 * Constants.D18, 10);
    }

    function getSpreadDemandComponentKfValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentKfValue;
    }

    function setSpreadDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE) {
        _demandComponentKfValue = newSpreadDemandComponentKfValue;
        emit SpreadDemandComponentKfValueSet(newSpreadDemandComponentKfValue);
    }

    function getSpreadDemandComponentLambdaValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentLambdaValue;
    }

    function setSpreadDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE) {
        _demandComponentLambdaValue = newSpreadDemandComponentLambdaValue;
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
        return _demandComponentKOmegaValue;
    }

    function setSpreadDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE) {
        _demandComponentKOmegaValue = newSpreadDemandComponentKOmegaValue;
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
        return _demandComponentMaxLiquidityRedemptionValue;
    }

    function setSpreadDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    )
        external
        override
        onlyRole(_SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE)
    {
        _demandComponentMaxLiquidityRedemptionValue = newSpreadDemandComponentMaxLiquidityRedemptionValue;
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
        return _atParComponentKVolValue;
    }

    function setSpreadAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE) {
        _atParComponentKVolValue = newSpreadAtParComponentKVolValue;
        emit SpreadAtParComponentKVolValueSet(newSpreadAtParComponentKVolValue);
    }

    function getSpreadAtParComponentKHistValue()
        external
        view
        override
        returns (uint256)
    {
        return _atParComponentKHistValue;
    }

    function setSpreadAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE) {
        _atParComponentKHistValue = newSpreadAtParComponentKHistValue;
        emit SpreadAtParComponentKHistValueSet(
            newSpreadAtParComponentKHistValue
        );
    }

    function getSpreadMaxValue() external view override returns (uint256) {
        return _maxValue;
    }

    function setSpreadMaxValue(uint256 newSpreadMaxValue)
        external
        override
        onlyRole(_SPREAD_MAX_VALUE_ROLE)
    {
        _maxValue = newSpreadMaxValue;
        emit SpreadMaxValueSet(newSpreadMaxValue);
    }
}
