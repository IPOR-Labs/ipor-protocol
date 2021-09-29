// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;
import "../libraries/types/DataTypes.sol";

interface IMiltonFrontendDataProvider {

    //TODO: prepare specific methods and structures for frontend

    function getMiltonTotalSupply(address asset) external view returns (uint256);

    function getMyTotalSupply(address asset) external view returns (uint256);

    function getMyAllowance(address asset) external view returns (uint256);

    function getPositions() external view returns (DataTypes.IporDerivative[] memory);

    function getMyPositions() external view returns (DataTypes.IporDerivative[] memory items);
}