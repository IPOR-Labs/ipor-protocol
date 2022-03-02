// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonStorage {
    function getVersion() external pure returns (uint256);

    function getLastSwapId() external view returns (uint256);

    function setMilton(address milton) external;

    function setJoseph(address joseph) external;

    function getBalance()
        external
        view
        returns (DataTypes.MiltonBalanceMemory memory);

    function getExtendedBalance()
        external
        view
        returns (DataTypes.MiltonExtendedBalanceMemory memory);

    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional);

    function addLiquidity(uint256 liquidityAmount) external;

    function subtractLiquidity(uint256 liquidityAmount) external;

    function updateStorageWhenTransferPublicationFee(uint256 transferedValue)
        external;

    function updateStorageWhenTransferTreasure(uint256 transferedValue)
        external;

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) external returns (uint256);

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) external returns (uint256);

    function updateStorageWhenCloseSwapPayFixed(
        address account,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) external;

    function updateStorageWhenCloseSwapReceiveFixed(
        address account,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) external;

    function updateStorageWhenWithdrawFromVault(
        uint256 withdrawnValue,
        uint256 vaultBalance
    ) external;

    function updateStorageWhenDepositToVault(
        uint256 depositValue,
        uint256 vaultBalance
    ) external;

    function getSwapPayFixed(uint256 swapId)
        external
        view
        returns (DataTypes.IporSwapMemory memory);

    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        returns (DataTypes.IporSwapMemory memory);

    function getSwapsPayFixed(address account)
        external
        view
        returns (DataTypes.IporSwapMemory[] memory);

    function getSwapsReceiveFixed(address account)
        external
        view
        returns (DataTypes.IporSwapMemory[] memory);

    function getSwapPayFixedIds(address account)
        external
        view
        returns (uint128[] memory);

    function getSwapReceiveFixedIds(address account)
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
