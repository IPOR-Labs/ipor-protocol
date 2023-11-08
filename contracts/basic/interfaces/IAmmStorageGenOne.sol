// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";
import "../../interfaces/types/AmmStorageTypes.sol";
import "../../amm/libraries/types/AmmInternalTypes.sol";

/// @title Interface for interaction with the IPOR AMM Storage, contract responsible for managing AMM storage.
interface IAmmStorageGenOne {
    /// @notice Returns the current version of AmmTreasury Storage
    /// @dev Increase number when the implementation inside source code is different that the implementation deployed on the Mainnet
    /// @return current AmmTreasury Storage version, integer
    function getVersion() external pure returns (uint256);

    /// @notice Gets the configuration of the IPOR AMM Storage.
    /// @return ammTreasury address of the AmmTreasury contract
    /// @return router address of the IPOR Protocol Router contract
    function getConfiguration() external view returns (address ammTreasury, address router);

    /// @notice Gets last swap ID.
    /// @dev swap ID is incremented when new position is opened, last swap ID is used in Pay Fixed and Receive Fixed swaps.
    /// @dev ID is global for all swaps, regardless if they are Pay Fixed or Receive Fixed in tenor 28, 60 or 90 days.
    /// @return last swap ID, integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets the last opened swap for a given tenor and direction.
    /// @param tenor tenor of the swap
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @return last opened swap {AmmInternalTypes.OpenSwapItem}
    function getLastOpenedSwap(
        IporTypes.SwapTenor tenor,
        uint256 direction
    ) external view returns (AmmInternalTypes.OpenSwapItem memory);

    /// @notice Gets the AMM balance struct
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.AmmBalancesMemory}
    function getBalance() external view returns (IporTypes.AmmBalancesMemory memory);

    /// @notice Gets the balance for open swap
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool balance
    /// # Total Notional Pay Fixed
    /// # Total Notional Receive Fixed
    /// @return balance structure {IporTypes.AmmBalancesForOpenSwapMemory}
    function getBalancesForOpenSwap() external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets the balance with the extended information: IPOR publication fee balance and Treasury balance.
    /// @return balance structure {AmmStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance() external view returns (AmmStorageTypes.ExtendedBalancesMemory memory);

    /// @notice gets the SOAP indicators.
    /// @dev SOAP is a Sum Of All Payouts, aka undealised PnL.
    /// @return indicatorsPayFixed structure {AmmStorageTypes.SoapIndicators} indicators for Pay Fixed swaps
    /// @return indicatorsReceiveFixed structure {AmmStorageTypes.SoapIndicators} indicators for Receive Fixed swaps
    function getSoapIndicators()
        external
        view
        returns (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        );

    /// @notice Gets swap based on the direction and swap ID.
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @param swapId swap ID
    /// @return swap structure {AmmTypesGenOne.sol.Swap}
    function getSwap(AmmTypes.SwapDirection direction, uint256 swapId) external view returns (AmmTypes.Swap memory);

    /// @notice Gets the active Pay-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed swaps
    /// @return swaps array where each element has structure {AmmTypesGenOne.sol.Swap}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Receive-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed swaps
    /// @return swaps array where each element has structure {AmmTypesGenOne.sol.Swap}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Pay-Fixed and Receive-Fixed swaps IDs for a given account address.
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

    /// @notice adds liquidity to the Liquidity Pool. Function available only to Router.
    /// @param account account address executing request for redeem asset amount
    /// @param assetAmount amount of asset added to balance of Liquidity Pool, represented in 18 decimals
    /// @param cfgMaxLiquidityPoolBalance max liquidity pool balance taken from AmmPoolsService configuration, represented in 18 decimals.
    /// @dev Function is only available to AmmPoolsService, can be executed only by IPOR Protocol Router as internal interaction.
    function addLiquidityInternal(address account, uint256 assetAmount, uint256 cfgMaxLiquidityPoolBalance) external;

    /// @notice subtract liquidity from the Liquidity Pool. Function available only to Router.
    /// @param assetAmount amount of asset subtracted from Liquidity Pool, represented in 18 decimals
    /// @dev Function is only available to AmmPoolsService, it can be executed only by IPOR Protocol Router as internal interaction.
    function subtractLiquidityInternal(uint256 assetAmount) external;

    /// @notice Updates structures in storage: balance, swaps, SOAP indicators when new Pay-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypesGenOne.sol.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when new Receive-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypesGenOne.sol.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapReceiveFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when closing Pay-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapPayFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates structures in the storage: swaps, balances, SOAP indicators when closing Receive-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates the balance when the AmmPoolsService withdraws AmmTreasury's assets from the AssetManagement.
    /// @dev Function is only available to the AmmTreasury contract.
    /// @param withdrawnAmount asset amount that was withdrawn from AssetManagement to AmmTreasury by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance Asset Management Vault (AssetManagement) balance, represented in 18 decimals
    function updateStorageWhenWithdrawFromAssetManagement(uint256 withdrawnAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService deposits AmmTreasury's assets to AssetManagement. Function is only available to AmmTreasury.
    /// @param depositAmount asset amount deposited from AmmTreasury to AssetManagement by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault(AssetManagement) balance , represented in 18 decimals
    function updateStorageWhenDepositToAssetManagement(uint256 depositAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Oracle Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Charlie Treasury multisig wallet.
    function updateStorageWhenTransferToCharlieTreasuryInternal(uint256 transferredAmount) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Treasury's multisig wallet.
    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external;
}
