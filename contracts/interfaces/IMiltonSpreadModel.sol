// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";

interface IMiltonSpreadModel {
    function calculateQuotePayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 quoteValue);

    function calculateSpreadPayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 spreadValue);

    function calculatePartialSpreadPayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 spreadValue);

    function calculatePartialSpreadRecFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        IMiltonStorage miltonStorage
    ) external view returns (uint256 spreadValue);
}
