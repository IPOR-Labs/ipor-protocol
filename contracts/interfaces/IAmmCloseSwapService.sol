// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/AmmTypes.sol";

/// @title Interface of the service allowing to close swaps.
interface IAmmCloseSwapService {
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

    /// @notice Closes batch of USDT swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @dev Swap PnL is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsUsdt(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of USDC swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap PnL is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsUsdc(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of DAI swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap PnL is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsDai(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of USDT swaps on both legs in emergency mode by Owner of Ipor Protocol Router.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function emergencyCloseSwapsUsdt(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of USDC swaps on both legs in emergency mode by Owner of Ipor Protocol Router.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function emergencyCloseSwapsUsdc(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of DAI swaps on both legs in emergency mode by Owner of Ipor Protocol Router.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function emergencyCloseSwapsDai(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );
}
