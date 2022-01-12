// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonSpreadConfiguration {
    event SpreadDemandComponentKfValueSet(
        uint256 newSpreadDemandComponentKfValue
    );

    event SpreadDemandComponentLambdaValueSet(
        uint256 newSpreadDemandComponentLambdaValue
    );

    event SpreadDemandComponentKOmegaValueSet(
        uint256 newSpreadDemandComponentKOmegaValue
    );

    event SpreadDemandComponentMaxLiquidityRedemptionValueSet(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    );

    event SpreadAtParComponentKVolValueSet(
        uint256 newSpreadAtParComponentKVolValue
    );

    event SpreadAtParComponentKHistValueSet(
        uint256 newSpreadAtParComponentKHistValue
    );

    event SpreadMaxValueSet(uint256 newSpreadMaxValue);

    function getDemandComponentKfValue() external view returns (uint256);

    function setDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external;

    function getDemandComponentLambdaValue()
        external
        view
        returns (uint256);

    function setDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    ) external;

    function getDemandComponentKOmegaValue()
        external
        view
        returns (uint256);

    function setDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    ) external;

    function getDemandComponentMaxLiquidityRedemptionValue()
        external
        view
        returns (uint256);

    function setDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    ) external;

    function getAtParComponentKVolValue() external view returns (uint256);

    function setAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    ) external;

    function getAtParComponentKHistValue()
        external
        view
        returns (uint256);

    function setAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    ) external;

    function getSpreadMaxValue() external view returns (uint256);

    function setSpreadMaxValue(uint256 newSpreadMaxValue) external;
}
