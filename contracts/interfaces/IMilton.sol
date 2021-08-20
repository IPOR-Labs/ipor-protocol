// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMilton {

    function getPositions() external view returns (DataTypes.IporDerivative[] memory);
    function getUserPositions(address user) external view returns (DataTypes.IporDerivative[] memory);
}