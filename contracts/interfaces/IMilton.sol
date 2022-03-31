// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for working Automated Market Maker.
interface IMilton {
    /// @notice Calculates Spread in current block.
    /// @return spreadPayFixed spread for Pay Fixed leg.
    /// @return spreadReceiveFixed spread for Receive Fixed leg.
    function calculateSpread()
        external
        view
        returns (uint256 spreadPayFixed, uint256 spreadReceiveFixed);

    /// @notice Calculates SOAP in current block
    /// @return soapPayFixed SOAP for Pay Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoap()
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Opens Pay Fixed, Receive Floating Swap for a given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from trader to Milton for the purpose of opening a position.
    /// @param maxAcceptableFixedInterestRate Max quote value which trader accept in case of changing quote
    /// value for external interactions other traders with Milton. Value represented in 18 decimals.
    /// @param leverage Leverage of this posistion
    /// @return Swap Id in Pay Fixed Swaps
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Opens Receive Fixed, Pay Floating Swap for a given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from trader to Milton for the purpose of opening a position.
    /// @param maxAcceptableFixedInterestRate Max quote value which trader accept in case of changing quote value for external
    /// interactions other traders with Milton. Value represented in 18 decimals.
    /// @param leverage Leverage of this posisiton
    /// @return Swap Id in Pay Fixed Swaps
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Closes Pay Fixed Swap for given id.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function closeSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function closeSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function closeSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function closeSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Emmited when trader opens new Swap.
    event OpenSwap(
        /// @notice swap id.
        uint256 indexed swapId,
        /// @notice trader who created this swap
        address indexed buyer,
        /// @notice underlying asset / stablecoin assocciated with this swap
        address asset,
        /// @notice swap direction
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice moment when swap was opened
        uint256 openTimestamp,
        /// @notice moment when swap will achieve maturiry and should be closed
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
    );

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap id.
        uint256 indexed swapId,
        /// @notice underlying asset / stablecoin assocciated with this swap
        address asset,
        /// @notice moment when Swap was closed
        uint256 closeTimestamp,
        /// @notice account who liquidate this Swap
        address liquidator,
        /// @notice asset amount after closing position which is transferred from Milton to Buyer
        uint256 transferredToBuyer,
        /// @notice asset amount after closing position which is transferred from Milton to Liquidator
        uint256 transferredToLiquidator
    );
}
