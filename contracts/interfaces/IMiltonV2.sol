// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypesV2.sol";

/// @title Interface for interaction with Milton.
interface IMiltonV2 {
    /// @notice Calculates spread for the current block.
    /// @dev All values represented in 18 decimals.
    /// @return spreadPayFixed spread for Pay-Fixed leg.
    /// @return spreadReceiveFixed spread for Receive-Fixed leg.
    function calculateSpread()
        external
        view
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed);

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

    /// @notice Opens Pay-Fixed (and Receive-Floating) swap with given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from the buyer to Milton for the purpose of opening a swap. Represented in decimals specific for asset.
    /// @param acceptableFixedInterestRate Max quote value which trader accepts in case of rate slippage. Value represented in 18 decimals.
    /// @param leverage Leverage used in this posistion. Value represented in 18 decimals.
    /// @return Swap ID in Pay-Fixed swaps list
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Opens Receive-Fixed (and Pay Floating) swap with given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from the buyer to Milton for the purpose of opening a swap. Represented in decimals specific for asset.
    /// @param acceptableFixedInterestRate Max quote value which trader accept in case of rate slippage. Value represented in 18 decimals.
    /// @param leverage Leverage used in this posisiton. Value represented in 18 decimals.
    /// @return Swap ID in Pay-Fixed swaps list
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Closes Pay-Fixed swap for given ID.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay-Fixed Swap ID.
    function closeSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive-Fixed swap for given ID.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
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
            MiltonTypesV2.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypesV2.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Emmited when trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        MiltonTypesV2.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypesV2.IporSwapIndicator indicator
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
}
