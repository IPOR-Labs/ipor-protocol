// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton.
interface IMilton {

    /// @notice Calculates the SOAP for the current block
    /// @dev All values represented in 18 decimals.
    /// @return soapPayFixed SOAP for Pay-Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive-Fixed leg.
    /// @return soap total SOAP - sum of Pay-Fixed and Receive-Fixed SOAP.
    function calculateSoap()
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Get closable status for Pay-Fixed swap.
    /// @param swapId Pay-Fixed swap ID.
    /// @return closableStatus Closable status for Pay-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForPayFixedSwap(uint256 swapId)
        external
        view
        returns (uint256 closableStatus);

    /// @notice Get closable status for Receive-Fixed swap.
    /// @param swapId Receive-Fixed swap ID.
    /// @return closableStatus Closable status for Receive-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForReceiveFixedSwap(uint256 swapId)
        external
        view
        returns (uint256 closableStatus);

    /// @notice Closes Pay-Fixed swap for given ID.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @dev Rejects transaction and returns error code IPOR_307 if swapId doesn't have AmmTypes.SwapState.ACTIVE status.
    /// @param swapId Pay-Fixed Swap ID.
    function closeSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive-Fixed swap for given ID.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @dev Rejects transaction and returns error code IPOR_307 if swapId doesn't have AmmTypes.SwapState.ACTIVE status.
    /// @param swapId Receive-Fixed swap ID.
    function closeSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes list of pay fixed and receive fixed swaps in one transaction.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset for every swap which was closed within this transaction.
    /// @param payFixedSwapIds list of pay fixed swap ids
    /// @param receiveFixedSwapIds list of receive fixed swap ids
    /// @return closedPayFixedSwaps list of pay fixed swaps with information which one was closed during this particular transaction.
    /// @return closedReceiveFixedSwaps list of receive fixed swaps with information which one was closed during this particular transaction.
    function closeSwaps(uint256[] memory payFixedSwapIds, uint256[] memory receiveFixedSwapIds)
        external
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    /// @notice Emmited when trader closes Swap.
    event SwapUnwind(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice payoff to date without unwind value, represented in 18 decimals
        int256 swapPayoffToDate,
        // @notice swap unwind value, represented in 18 decimals
        int256 swapUnwindValue,
        // @notice swap unwind value, represented in 18 decimals
        uint256 swapUnwindOpeningFee
    );
}
