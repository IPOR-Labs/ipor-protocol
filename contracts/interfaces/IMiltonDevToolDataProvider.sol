// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMiltonDevToolDataProvider {

    function getMiltonTotalSupply(address asset) external view returns (uint256);

    function getMyTotalSupply(address asset) external view returns (uint256);

    function getMyIporTokenBalance(address asset) external view returns (uint256);

    function getMyAllowanceInMilton(address asset) external view returns (uint256);

    function getMyAllowanceInJoseph(address asset) external view returns (uint256);

    function getPositions() external view returns (DataTypes.IporDerivative[] memory);

    function getMyPositions() external view returns (DataTypes.IporDerivative[] memory items);
}
