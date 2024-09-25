// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "./types/AmmTypes.sol";

/// @title Interface of the service allowing to close swaps in stETH AMM.
interface IAmmCloseSwapServiceWstEth {
    /// @notice Closes batch of wstETH swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap PnL is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsWstEth(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of wstETH swaps on both legs in emergency mode by Owner of Ipor Protocol Router.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function emergencyCloseSwapsWstEth(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );
}
