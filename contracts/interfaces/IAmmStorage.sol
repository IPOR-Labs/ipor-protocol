// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/AmmStorageTypes.sol";

/// @title Interface for interaction with AmmTreasury Storage smart contract, reposnsible for managing AMM storage.
interface IAmmStorage {
    /// @notice Returns current version of AmmTreasury Storage
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current AmmTreasury Storage version, integer
    function getVersion() external pure returns (uint256);

    function getIporProtocolRouter() external view returns (address);

    /// @notice Gets last swap ID.
    /// @dev swap ID is incremented when new position is opened, last swap ID is used in Pay Fixed and Receive Fixed swaps.
    /// @return last swap ID, integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets balance struct
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.AmmBalancesMemory}
    function getBalance() external view returns (IporTypes.AmmBalancesMemory memory);

    /// @notice Gets balance for open swap
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool balance
    /// # Total Notional Pay Fixed
    /// # Total Notional Receive Fixed
    /// @return balance structure {IporTypes.AmmBalancesForOpenSwapMemory}
    function getBalancesForOpenSwap() external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets balance with extended information: IPOR publication fee balance and Treasury balance.
    /// @return balance structure {AmmStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance() external view returns (AmmStorageTypes.ExtendedBalancesMemory memory);

    /// @notice Gets total outstanding notional.
    /// @return totalNotionalPayFixed Sum of notional amount of all swaps for Pay-Fixed leg, represented in 18 decimals
    /// @return totalNotionalReceiveFixed Sum of notional amount of all swaps for Receive-Fixed leg, represented in 18 decimals
    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 totalNotionalPayFixed, uint256 totalNotionalReceiveFixed);

    /// @notice Gets Pay-Fixed swap for a given swap ID
    /// @param swapId swap ID.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapPayFixed(uint256 swapId) external view returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets Receive-Fixed swap for a given swap ID
    /// @param swapId swap ID.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapReceiveFixed(uint256 swapId) external view returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets active Pay-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed swaps
    /// @return swaps array where each element has structure {IporTypes.IporSwapMemory}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets active Receive-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed swaps
    /// @return swaps array where each element has structure {IporTypes.IporSwapMemory}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets active Pay-Fixed swaps IDs for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed IDs
    /// @return ids list of IDs
    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint256[] memory ids);

    /// @notice Gets active Receive-Fixed swaps IDs for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive-Fixed IDs
    /// @return ids list of IDs
    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint256[] memory ids);

    /// @notice Gets active Pay-Fixed and Receive-Fixed swaps IDs for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed and Receive-Fixed IDs.
    /// @return ids array where each element has structure {AmmStorageTypes.IporSwapId}
    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids);

    /// @notice Calculates SOAP for a given IBT price and timestamp. For more information refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/soap
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapPayFixed SOAP for Pay-Fixed and Receive-Floating leg, represented in 18 decimals
    /// @return soapReceiveFixed SOAP for Receive-Fixed and Pay-Floating leg, represented in 18 decimals
    /// @return soap Sum of SOAP for Pay-Fixed leg and Receive-Fixed leg , represented in 18 decimals
    function calculateSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculates SOAP for Pay-Fixed leg at given IBT price and time.
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapPayFixed SOAP for Pay-Fixed leg, represented in 18 decimals
    function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (int256 soapPayFixed);

    /// @notice Calculates SOAP for Receive-Fixed leg at given IBT price and time.
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapReceiveFixed SOAP for Receive-Fixed leg, represented in 18 decimals
    function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (int256 soapReceiveFixed);

    /// @notice add liquidity to the Liquidity Pool. Function available only to Router.
    /// @param account account address who execute request for redeem asset amount
    /// @param assetAmount amount of asset added to balance of Liquidity Pool, represented in 18 decimals
    /// @param cfgMaxLiquidityPoolBalance max liquidity pool balance taken from Joseph configuration, represented in 18 decimals.
    /// @param cfgMaxLpAccountContribution max liquidity pool account contribution taken from AMM configuration, represented in 18 decimals.
    function addLiquidity(
        address account,
        uint256 assetAmount,
        uint256 cfgMaxLiquidityPoolBalance,
        uint256 cfgMaxLpAccountContribution
    ) external;

    /// @notice subtract liquidity from the Liquidity Pool. Function available only to Router.
    /// @param assetAmount amount of asset subtracted from Liquidity Pool, represented in 18 decimals
    function subtractLiquidity(uint256 assetAmount) external;

    /// @notice Updates structures in storage: balance, swaps, SOAP indicators when new Pay-Fixed swap is opened. Function available only to AmmTreasury.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapPayFixed(AmmTypes.NewSwap memory newSwap, uint256 cfgIporPublicationFee)
        external
        returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when new Receive-Fixed swap is opened. Function is only available to AmmTreasury.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapReceiveFixed(AmmTypes.NewSwap memory newSwap, uint256 cfgIporPublicationFee)
        external
        returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when closing Pay-Fixed swap. Function is only available to AmmTreasury.
    /// @param iporSwap swap structure {IporTypes.IporSwapMemory}
    /// @param payoff amount that trader has earned or lost on the swap, represented in 18 decimals, it can be negative.
    /// @param closingTimestamp moment when the swap was closed
    function updateStorageWhenCloseSwapPayFixed(
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closingTimestamp
    ) external;

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when closing Receive-Fixed swap.
    /// Function is only available to AmmTreasury.
    /// @param iporSwap swap structure {IporTypes.IporSwapMemory}
    /// @param payoff amount that trader has earned or lost, represented in 18 decimals, can be negative.
    /// @param closingTimestamp moment when swap was closed
    function updateStorageWhenCloseSwapReceiveFixed(
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closingTimestamp
    ) external;

    /// @notice Updates the balance when Joseph withdraws AmmTreasury's assets from AssetManagement. Function is only available to AmmTreasury.
    /// @param withdrawnAmount asset amount that was withdrawn from AssetManagement to AmmTreasury by Joseph, represented in 18 decimals.
    /// @param vaultBalance Asset Management Vault (AssetManagement) balance, represented in 18 decimals
    function updateStorageWhenWithdrawFromAssetManagement(uint256 withdrawnAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when Joseph deposits AmmTreasury's assets to AssetManagement. Function is only available to AmmTreasury.
    /// @param depositAmount asset amount deposited from AmmTreasury to AssetManagement by Joseph, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault(AssetManagement) balance , represented in 18 decimals
    function updateStorageWhenDepositToAssetManagement(uint256 depositAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when Joseph transfers AmmTreasury's assets to Charlie Treasury's multisig wallet. Function is only available to Joseph.
    /// @param transferredAmount asset amount transferred to Charlie Treasury multisig wallet.
    function updateStorageWhenTransferToCharlieTreasury(uint256 transferredAmount) external;

    /// @notice Updates the balance when Joseph transfers AmmTreasury's assets to Treasury's multisig wallet. Function is only available to Joseph.
    /// @param transferredAmount asset amount transferred to Treasury's multisig wallet.
    function updateStorageWhenTransferToTreasury(uint256 transferredAmount) external;

    /// @notice Sets AMM Treasury's address. Function is only available to the smart contract Owner.
    /// @param ammTreasury AMMTreasury's address
    function setAmmTreasury(address ammTreasury) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Amm Treasury.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AmmTreasury.
    function unpause() external;

    /// @notice Emitted when AMM Treausury address has changed by the smart contract Owner.
    /// @param changedBy account address that has changed AmmTreasury's address
    /// @param oldAmmTreasury old AmmTreasury's address
    /// @param newAmmTreasury new AmmTreasury's address
    event AmmTreasuryChanged(address changedBy, address oldAmmTreasury, address newAmmTreasury);
}
