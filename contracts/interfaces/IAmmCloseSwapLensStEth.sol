// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/AmmTypes.sol";
import "./IAmmCloseSwapLens.sol";
import "../base/types/AmmTypesBaseV1.sol";

/// @title Interface of the CloseSwap Lens for stETH AMM.
interface IAmmCloseSwapLensStEth {
    /// @notice Returns the closing swap details for a given swap and closing timestamp.
    /// @param account account address for which are returned closing swap details, for example closableStatus depends on the account
    /// @param direction swap direction
    /// @param swapId swap id
    /// @param closeTimestamp closing timestamp
    /// @return closingSwapDetails struct representing the closing swap details for a given swap and closing timestamp.
    function getClosingSwapDetailsStEth(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) external view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails);
}
