// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonAssetSpreadConfiguration {
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

    function getSpreadDemandComponentKfValue() external view returns (uint256);

    function setSpreadDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external;

    function getSpreadDemandComponentLambdaValue()
        external
        view
        returns (uint256);

    function setSpreadDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    ) external;

    function getSpreadDemandComponentKOmegaValue()
        external
        view
        returns (uint256);

    function setSpreadDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    ) external;

    function getSpreadDemandComponentMaxLiquidityRedemptionValue()
        external
        view
        returns (uint256);

    function setSpreadDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    ) external;

    function getSpreadAtParComponentKVolValue() external view returns (uint256);

    function setSpreadAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    ) external;

    function getSpreadAtParComponentKHistValue()
        external
        view
        returns (uint256);

    function setSpreadAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    ) external;

    function getSpreadMaxValue() external view returns (uint256);

    function setSpreadMaxValue(uint256 newSpreadMaxValue) external;
}
