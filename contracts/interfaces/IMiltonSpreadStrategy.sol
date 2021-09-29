// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMiltonSpreadStrategy {

    function calculateSpread(address asset, uint256 calculateTimestamp) external view returns (uint256 spreadPf, uint256 spreadRf);
}