// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonStorageTypes.sol";

interface IMiltonStorage {
    function getVersion() external pure returns (uint256);

    function getLastSwapId() external view returns (uint256);

    function getBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    function getExtendedBalance()
        external
        view
        returns (MiltonStorageTypes.ExtendedBalancesMemory memory);

    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional);

    function getSwapPayFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids);

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

    function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (int256 soapRf);

    function addLiquidity(uint256 liquidityAmount) external;

    function subtractLiquidity(uint256 liquidityAmount) external;

    function updateStorageWhenOpenSwapPayFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFeeAmount
    ) external returns (uint256);

    function updateStorageWhenOpenSwapReceiveFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFeeAmount
    ) external returns (uint256);

    function updateStorageWhenCloseSwapPayFixed(
        address account,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeePercentage,
        uint256 minPercentagePositionValueToCloseBeforeMaturity,
        uint256 secondsToMaturityWhenPositionCanBeClosed
    ) external;

    function updateStorageWhenCloseSwapReceiveFixed(
        address account,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeePercentage,
        uint256 minPercentagePositionValueToCloseBeforeMaturity,
        uint256 secondsToMaturityWhenPositionCanBeClosed
    ) external;

    function updateStorageWhenWithdrawFromStanley(uint256 withdrawnValue, uint256 vaultBalance)
        external;

    function updateStorageWhenDepositToStanley(uint256 depositValue, uint256 vaultBalance) external;

    function updateStorageWhenTransferToCharlieTreasury(uint256 transferredValue) external;

    function updateStorageWhenTransferToTreasury(uint256 transferredValue) external;

    function setMilton(address milton) external;

    function setJoseph(address joseph) external;
}
