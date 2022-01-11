// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonSpreadModel {
    function calculatePartialSpreadPayFixed(
        uint256 calculateTimestamp,
        address asset
    ) external view returns (uint256 spreadValue);

    function calculateSpreadPayFixed(
        uint256 calculateTimestamp,
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    ) external view returns (uint256 spreadValue);

    function calculatePartialSpreadRecFixed(
        uint256 calculateTimestamp,
        address asset
    ) external view returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        uint256 calculateTimestamp,
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    ) external view returns (uint256 spreadValue);
}
