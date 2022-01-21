// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";

interface IMiltonSpreadModel {
    function calculatePartialSpreadPayFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor
    ) external view returns (uint256 spreadValue);

    function calculateSpreadPayFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    ) external view returns (uint256 spreadValue);

    function calculatePartialSpreadRecFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor
    ) external view returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    ) external view returns (uint256 spreadValue);
}
