// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMiltonLPUtilizationStrategy {

    function calculateUtilization(string memory asset) external view returns (uint256);
}