// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./types/AmmTypes.sol";
import "../base/types/AmmTypesBaseV1.sol";

interface ISwapEventsBaseV1 {

    /// @notice Emitted when the trader opens new swap.
    event OpenSwap(
    /// @notice swap ID.
        uint256 indexed swapId,
    /// @notice trader that opened the swap
        address indexed buyer,
    /// @notice Account input token address
        address inputAsset,
    /// @notice underlying asset
        address asset,
    /// @notice swap direction, Pay Fixed Receive Floating or Pay Floating Receive Fixed.
        AmmTypes.SwapDirection direction,
    /// @notice technical structure with amounts related with this swap
        AmmTypesBaseV1.OpenSwapAmount amounts,
    /// @notice the moment when swap was opened
        uint256 openTimestamp,
    /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
    /// @notice specific indicators related with this swap
        AmmTypes.IporSwapIndicator indicator
    );

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
}
