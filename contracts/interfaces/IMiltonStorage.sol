// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMiltonStorage {

    function getBalance(address asset) external view returns (DataTypes.MiltonTotalBalance memory);

    function getLastDerivativeId() external view returns (uint256);

    function addLiquidity(address asset, uint256 liquidityAmount) external;

    function subtractLiquidity(address asset, uint256 liquidityAmount) external;

    function updateStorageWhenTransferPublicationFee(address asset, uint256 transferedAmount) external;

    function updateStorageWhenOpenPosition(DataTypes.IporDerivative memory iporDerivative) external;

    function updateStorageWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp) external;

    function getDerivativeItem(uint256 derivativeId) external view returns (DataTypes.MiltonDerivativeItem memory);

    function getPositions() external view returns (DataTypes.IporDerivative[] memory);

    function getUserPositions(address user) external view returns (DataTypes.IporDerivative[] memory);

    function getDerivativeIds() external view returns (uint256[] memory);

    function getUserDerivativeIds(address userAddress) external view returns (uint256[] memory);

    function calculateSpread(address asset, uint256 calculateTimestamp) external view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);

    function calculateSoap(address asset, uint256 ibtPrice, uint256 calculateTimestamp) external view returns (int256 soapPf, int256 soapRf, int256 soap);

    function addAsset(address asset) external;
}
