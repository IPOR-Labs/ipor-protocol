// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMiltonDevToolDataProvider {

    function getTokenAddress(string memory asset) external view returns (address);

    function getMiltonTotalSupply(string memory asset) external view returns (uint256);

    function getMyTotalSupply(string memory asset) external view returns (uint256);

    function getMyAllowance(string memory asset) external view returns (uint256);

    function getPositions() external view returns (DataTypes.IporDerivative[] memory);

    function getMyPositions() external view returns (DataTypes.IporDerivative[] memory items);
}