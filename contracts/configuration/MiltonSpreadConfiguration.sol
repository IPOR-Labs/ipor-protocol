// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../interfaces/IMiltonSpreadConfiguration.sol";
import "./AccessControlMiltonSpreadConfiguration.sol";

contract MiltonSpreadConfiguration is
    AccessControlMiltonSpreadConfiguration(msg.sender),
    IMiltonSpreadConfiguration
{
	//TODO: [gas-opt] decrease size and use struct in Spread Model

	//@notice Spread Max Value
    uint64 internal _maxValue;

	//TODO: consider combine demand component values as one structs
    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint64 internal _demandComponentKfValue;

    //@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint64 internal _demandComponentLambdaValue;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint64 internal _demandComponentKOmegaValue;

    //@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint64 internal _demandComponentMaxLiquidityRedemptionValue;

    //@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint64 internal _atParComponentKVolValue;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint64 internal _atParComponentKHistValue;    

    constructor() {
        _demandComponentKfValue = uint64(IporMath.division(
            Constants.D18,
            100
        ));
        _demandComponentLambdaValue = uint64(IporMath.division(
            Constants.D18,
            100
        ));
        _demandComponentKOmegaValue = uint64(IporMath.division(
            Constants.D18,
            100
        ));

        _demandComponentMaxLiquidityRedemptionValue = uint64(Constants.D18);
        
        _atParComponentKVolValue = uint64(IporMath.division(
            Constants.D18,
            100
        ));

        _atParComponentKHistValue = uint64(IporMath.division(
            Constants.D18,
            100
        ));

        _maxValue = uint64(IporMath.division(3 * Constants.D16, 10));
    }

	function getSpreadMaxValue() external view override returns (uint256) {
        return _maxValue;
    }

    function setSpreadMaxValue(uint256 newSpreadMaxValue)
        external
        override
        onlyRole(_SPREAD_MAX_VALUE_ROLE)
    {
        _maxValue = uint64(newSpreadMaxValue);
        emit SpreadMaxValueSet(newSpreadMaxValue);
    }

    function getDemandComponentKfValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentKfValue;
    }

    function setDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE) {
        _demandComponentKfValue = uint64(newSpreadDemandComponentKfValue);
        emit SpreadDemandComponentKfValueSet(newSpreadDemandComponentKfValue);
    }

    function getDemandComponentLambdaValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentLambdaValue;
    }

    function setDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE) {
        _demandComponentLambdaValue = uint64(newSpreadDemandComponentLambdaValue);
        emit SpreadDemandComponentLambdaValueSet(
            newSpreadDemandComponentLambdaValue
        );
    }

    function getDemandComponentKOmegaValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentKOmegaValue;
    }

    function setDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    ) external override onlyRole(_SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE) {
        _demandComponentKOmegaValue = uint64(newSpreadDemandComponentKOmegaValue);
        emit SpreadDemandComponentKOmegaValueSet(
            newSpreadDemandComponentKOmegaValue
        );
    }

    function getDemandComponentMaxLiquidityRedemptionValue()
        external
        view
        override
        returns (uint256)
    {
        return _demandComponentMaxLiquidityRedemptionValue;
    }

    function setDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    )
        external
        override
        onlyRole(_SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE)
    {
        _demandComponentMaxLiquidityRedemptionValue = uint64(newSpreadDemandComponentMaxLiquidityRedemptionValue);
        emit SpreadDemandComponentMaxLiquidityRedemptionValueSet(
            newSpreadDemandComponentMaxLiquidityRedemptionValue
        );
    }

    function getAtParComponentKVolValue()
        external
        view
        override
        returns (uint256)
    {
        return _atParComponentKVolValue;
    }

    function setAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE) {
        _atParComponentKVolValue = uint64(newSpreadAtParComponentKVolValue);
        emit SpreadAtParComponentKVolValueSet(newSpreadAtParComponentKVolValue);
    }

    function getAtParComponentKHistValue()
        external
        view
        override
        returns (uint256)
    {
        return _atParComponentKHistValue;
    }

    function setAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    ) external override onlyRole(_SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE) {
        _atParComponentKHistValue = uint64(newSpreadAtParComponentKHistValue);
        emit SpreadAtParComponentKHistValueSet(
            newSpreadAtParComponentKHistValue
        );
    }    
}
