// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonSpreadModel {
    function calculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);
}
