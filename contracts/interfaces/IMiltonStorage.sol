// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonStorageTypes.sol";

/// @title Interface for interaction with Milton Storage smart contract, which is reposnsible for managing AMM storage.
interface IMiltonStorage {
    /// @notice Returns current version of Milton Storage's
    /// @return current Milton Storage version, this is integer.
    function getVersion() external pure returns (uint256);

    /// @notice Gets lasw swap Id.
    /// @dev swap id is incremented when new position is opened, last swap id is used in Pay Fixed and Receive Fixed swaps.
    /// @return last swap id, this is integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets balance struct
    /// @dev Balance contain, Pay Fixed Total Collateral, Receive Fixed Total Collateral, Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.MiltonBalancesMemory}
    function getBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    /// @notice Gets balance with extended information like IPOR publication fee balance and Treasury balance.
    /// @return balance structure {MiltonStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance()
        external
        view
        returns (MiltonStorageTypes.ExtendedBalancesMemory memory);

    /// @notice Gets total outstanding notional.
    /// @return payFixedTotalNotional total notional balance for Pay Fixed leg, represented in 18 decimals
    /// @return recFixedTotalNotional total notional balance for Receive Fixed leg, represented in 18 decimals
    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional);

    /// @notice Gets Pay Fixed Swap for a given swap id
    /// @param swapId swap id.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapPayFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets Receive Fixed Swap for a given swap id
    /// @param swapId swap id.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets Pay Fixed active swaps for a given account address.
    /// @param account account address
    /// @param offset
    /// @param chunkSize
	/// @return totalCount
    /// @return swaps array where one element is {IporTypes.IporSwapMemory}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

	/// @notice Gets Receive Fixed active swaps for a given account address.
    /// @param account account address
    /// @param offset
    /// @param chunkSize
	/// @return totalCount
    /// @return swaps array where one element is {IporTypes.IporSwapMemory}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

	/// @notice Gets Pay Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset
    /// @param chunkSize
	/// @return totalCount
    /// @return ids list of ids
    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

	/// @notice Gets Receive Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset
    /// @param chunkSize
	/// @return totalCount
    /// @return ids list of ids
    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

	/// @notice Gets Pay Fixed and Receive Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset
    /// @param chunkSize
	/// @return totalCount
    /// @return swaps array where one element is {MiltonStorageTypes.IporSwapId}
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

    event MiltonChanged(address changedBy, address newMilton);

    event JosephChanged(address changedBy, address newJoseph);

    //TODO: pause and unpause
}
