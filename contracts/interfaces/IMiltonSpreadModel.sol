// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonSpreadModel {
    function calculateSpread(
        uint256 calculateTimestamp,
        address asset,
        uint8 derivativeDirection,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    )
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);

    function calculateSpreadPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) external view returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) external view returns (uint256 spreadValue);
}
