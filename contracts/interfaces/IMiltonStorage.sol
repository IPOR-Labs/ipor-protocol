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
    ) external returns (uint256);

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount
    ) external returns (uint256);

    function updateStorageWhenCloseSwapPayFixed(
        address user,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp
    ) external;

    function updateStorageWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp
    ) external;

    function getSwapPayFixedItem(uint256 swapId)
        external
        view
        returns (DataTypes.IporSwapMemory memory);

    function getSwapPayFixedState(uint256 swapId)
        external
        view
        returns (uint256);

    function getSwapReceiveFixedState(uint256 swapId)
        external
        view
        returns (uint256);

    function getSwapReceiveFixedItem(uint256 swapId)
        external
        view
        returns (DataTypes.IporSwapMemory memory);
    
    function getSwapsPayFixed(address user)
        external
        view
        returns (DataTypes.IporSwapMemory[] memory);

    function getSwapsReceiveFixed(address user)
        external
        view
        returns (DataTypes.IporSwapMemory[] memory);

    function getUserSwapPayFixedIds(address userAddress)
        external
        view
        returns (uint128[] memory);

    function getUserSwapReceiveFixedIds(address userAddress)
        external
        view
        returns (uint128[] memory);

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
        returns (int256 soapPf);

    function calculateSoapReceiveFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) external view returns (int256 soapRf);
}
