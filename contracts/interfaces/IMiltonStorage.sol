// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonStorage {
    function getBalance()
        external
        view
        returns (DataTypes.MiltonTotalBalanceMemory memory);

    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional);

    function getLastSwapId() external view returns (uint256);

    function addLiquidity(uint256 liquidityAmount) external;

    function subtractLiquidity(uint256 liquidityAmount) external;

    function updateStorageWhenTransferPublicationFee(uint256 transferedAmount)
        external;

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount
    ) external returns(uint256);

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount
    ) external returns(uint256);

    function updateStorageWhenCloseSwapPayFixed(
        address user,
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external;

    function updateStorageWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external;

    function getSwapPayFixedItem(uint256 derivativeId)
        external
        view
        returns (DataTypes.MiltonDerivativeItemMemory memory);

    function getSwapPayFixedState(uint256 swapId)
        external
        view
        returns (uint256);

    function getSwapReceiveFixedState(uint256 swapId)
        external
        view
        returns (uint256);

    function getSwapReceiveFixedItem(uint256 derivativeId)
        external
        view
        returns (DataTypes.MiltonDerivativeItemMemory memory);

    function getSwapsPayFixed()
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

    function getSwapsReceiveFixed()
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

    function getUserSwapsPayFixed(address user)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

    function getUserSwapsReceiveFixed(address user)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

    function getSwapPayFixedIds() external view returns (uint256[] memory);

    function getSwapReceiveFixedIds() external view returns (uint256[] memory);

    function getUserSwapPayFixedIds(address userAddress)
        external
        view
        returns (uint256[] memory);

    function getUserSwapReceiveFixedIds(address userAddress)
        external
        view
        returns (uint256[] memory);

    function calculateSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        );
		function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf
        );
		function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapRf
        );
}
