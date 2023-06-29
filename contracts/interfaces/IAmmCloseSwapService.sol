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

    /// @notice Emitted when the trader closes the swap before maturity or if the absolute value of the swap's payoff is less than 99% of the swap's collateral.
    event SwapUnwind(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice payoff to date without unwind value, represented in 18 decimals
        int256 swapPayoffToDate,
        /// @notice swap unwind amount, represented in 18 decimals
        int256 swapUnwindAmount,
        /// @notice opening fee amount, part earmarked for the liquidity pool, represented in 18 decimals
        uint256 openingFeeLPAmount,
        /// @notice opening fee amount, part earmarked for the treasury, represented in 18 decimals
        uint256 openingFeeTreasuryAmount
    );

    /// @notice Closes batch of USDT swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @dev Swap payoff is always transferred to the swaps's owner.
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
    /// @dev Swap payoff is always transferred to the swaps's owner.
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
    /// @dev Swap payoff is always transferred to the swaps's owner.
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

    function emergencyCloseSwapsUsdt(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    function emergencyCloseSwapsUsdc(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

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
