// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton.
interface IMilton {
    /// @notice Calculates spread for the current block.
    /// @return spreadPayFixed spread for Pay-Fixed leg.
    /// @return spreadReceiveFixed spread for Receive-Fixed leg.
    function calculateSpread()
        external
        view
        returns (uint256 spreadPayFixed, uint256 spreadReceiveFixed);

    /// @notice Calculates the SOAP for the current block
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
    /// @param totalAmount Total amount transferred from the buyer to Milton for the purpose of opening a swap.
    /// @param acceptableFixedInterestRate Max quote value which trader accepts in case of rate slippage.
    /// Value represented in 18 decimals.
    /// @param leverage Leverage used in this posistion
    /// @return Swap ID in Pay-Fixed swaps list
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Opens Receive-Fixed (and Pay Floating) swap with given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from the buyer to Milton for the purpose of opening a swap.
    /// @param acceptableFixedInterestRate Max quote value which trader accept in case of rate slippage.
    /// Value represented in 18 decimals.
    /// @param leverage Leverage used in this posisiton
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

    /// @notice Closes Pay-Fixed swaps for given list of IDs.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay-Fixed swaps IDs.
    function closeSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive-Fixed swaps for given list of IDs.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive-Fixed swaps.
    function closeSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Emmited when trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction 
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
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
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator
        uint256 transferredToLiquidator
    );
}
