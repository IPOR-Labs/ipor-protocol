// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IMiltonSpreadConfiguration {
    function getSpreadPremiumsMaxValue() external pure returns (uint256);

    function getDCKfValue() external pure returns (uint256);

    function getDCLambdaValue() external pure returns (uint256);

    function getDCKOmegaValue() external pure returns (uint256);

    function getDCMaxLiquidityRedemptionValue() external pure returns (uint256);

    function getAtParComponentKVolValue() external pure returns (uint256);

    function getAtParComponentKHistValue() external pure returns (uint256);
}
