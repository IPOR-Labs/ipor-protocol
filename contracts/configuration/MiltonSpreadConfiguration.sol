// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../interfaces/IMiltonSpreadConfiguration.sol";
import "./AccessControlMiltonSpreadConfiguration.sol";

contract MiltonSpreadConfiguration is
    AccessControlMiltonSpreadConfiguration,
    IMiltonSpreadConfiguration
{
    using SafeCast for uint256;
    //TODO: [gas-opt] move to immutable all fields here

    //@notice Spread Max Value
    uint64 internal _maxValue;

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

    function getSpreadMaxValue() external view override returns (uint256) {
        return _maxValue;
    }

    function setSpreadMaxValue(uint256 newSpreadMaxValue)
        external
        override
        onlyRole(_SPREAD_MAX_VALUE_ROLE)
    {
        _maxValue = newSpreadMaxValue.toUint64();
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

    function setDemandComponentKfValue(uint256 newSpreadDemandComponentKfValue)
        external
        override
        onlyRole(_SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE)
    {
        _demandComponentKfValue = newSpreadDemandComponentKfValue.toUint64();
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
        _demandComponentLambdaValue = newSpreadDemandComponentLambdaValue
            .toUint64();
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
        _demandComponentKOmegaValue = newSpreadDemandComponentKOmegaValue
            .toUint64();
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
        _demandComponentMaxLiquidityRedemptionValue = newSpreadDemandComponentMaxLiquidityRedemptionValue
            .toUint64();
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
        _atParComponentKVolValue = newSpreadAtParComponentKVolValue.toUint64();
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
        _atParComponentKHistValue = newSpreadAtParComponentKHistValue.toUint64();
        emit SpreadAtParComponentKHistValueSet(
            newSpreadAtParComponentKHistValue
        );
    }
}
