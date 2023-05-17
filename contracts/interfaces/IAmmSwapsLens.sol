// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporTypes.sol";

interface IAmmSwapsLens {

    /// @notice Get closable status for Pay-Fixed swap.
    /// @param asset Address of the asset.
    /// @param swapId Pay-Fixed swap ID.
    /// @return closableStatus Closable status for Pay-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForPayFixedSwap(address asset, uint256 swapId)
        external
        view
        returns (uint256 closableStatus);

    /// @notice Get closable status for Receive-Fixed swap.
    /// @param asset Address of the asset.
    /// @param swapId Receive-Fixed swap ID.
    /// @return closableStatus Closable status for Receive-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForReceiveFixedSwap(address asset, uint256 swapId)
        external
        view
        returns (uint256 closableStatus);

    /// @notice Gets the list of active Pay Fixed Receive Floating swaps in Milton for a given asset and address
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is scoped
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay Fixed swaps in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets the list of active Receive Fixed Pay Floating Swaps in Milton for a given asset and address
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is scoped
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of Receive Fixed swaps in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets list of active Pay Fixed Receive Floating Swaps in Milton of sender for a given asset
    /// @param asset asset / stablecoin address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of Pay Fixed swaps in Milton for a current user
    /// @return swaps list of active swaps for a given asset
    function getMySwapsPayFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets list of active Receive Fixed Pay Floating Swaps in Milton of sender for a given asset
    /// @param asset asset / stablecoin address
    /// @param offset offset for paging functionality purposes
    /// @param chunkSize page size for paging functionality purposes
    /// @return totalCount total amount of Receive Fixed swaps in Milton for a current user
    /// @return swaps list of active swaps for a given asset
    function getMySwapsReceiveFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets active swaps for a given asset sender address (aka buyer).
    /// @param asset asset address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of sender's active swaps in Milton
    /// @return swaps list of active sender's swaps
    function getMySwaps(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice IPOR Swap structure.
    struct IporSwap {
        /// @notice Swap ID.
        uint256 id;
        /// @notice Swap asset (stablecoint / underlying token)
        address asset;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap collateral, represented in 18 decimals.
        uint256 collateral;
        /// @notice Notional amount, represented in 18 decimals.
        uint256 notional;
        /// @notice Swap leverage, represented in 18 decimals.
        uint256 leverage;
        /// @notice Swap direction
        /// @dev 0 - Pay Fixed-Receive Floating, 1 - Receive Fixed - Pay Floading
        uint256 direction;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate.
        uint256 fixedInterestRate;
        /// @notice Current position value, represented in 18 decimals.
        int256 payoff;
        /// @notice Moment when swap was opened.
        uint256 openTimestamp;
        /// @notice Moment when swap achieve its maturity.
        uint256 endTimestamp;
        /// @notice Liqudidation deposit value on day when swap was opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
    }
}
