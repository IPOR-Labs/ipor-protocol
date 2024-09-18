// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

library AmmEventsBaseV1 {
    /// @notice Emitted when the trader closes the swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    /// @notice Emitted when unwind is performed during closing swap.
    event SwapUnwind(
        /// @notice underlying asset
        address asset,
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice Profit and Loss to date without unwind value, represented in 18 decimals
        int256 swapPnlValueToDate,
        /// @notice swap unwind amount, represented in 18 decimals
        int256 swapUnwindAmount,
        /// @notice unwind fee amount, part earmarked for the liquidity pool, represented in 18 decimals
        uint256 unwindFeeLPAmount,
        /// @notice unwind fee amount, part earmarked for the treasury, represented in 18 decimals
        uint256 unwindFeeTreasuryAmount
    );

    event SpreadTimeWeightedNotionalChanged(
        /// @notice timeWeightedNotionalPayFixed with 18 decimals
        uint256 timeWeightedNotionalPayFixed,
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed,
        /// @notice timeWeightedNotionalReceiveFixed with 18 decimals
        uint256 timeWeightedNotionalReceiveFixed,
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed,
        /// @notice storageId from SpreadStorageLibsBaseV1.StorageId or from SpreadStorageLibs.StorageId depends on asset
        /// @dev If asset is USDT, USDC, DAI then sender is a IporProtocolRouterEthereum.sol, if asset is stETH sender is a SpreadStEth contract
        uint256 storageId
    );
}
