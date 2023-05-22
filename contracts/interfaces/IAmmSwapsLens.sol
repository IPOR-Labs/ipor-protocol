// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporTypes.sol";

interface IAmmSwapsLens {
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

    /// @notice Gets active swaps for a given asset sender address (aka buyer).
    /// @param asset asset address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of sender's active swaps in Milton
    /// @return swaps list of active sender's swaps
    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    function getPayoffPayFixed(address asset, uint256 swapId) external view returns (int256 payoff);

    function getPayoffReceiveFixed(address asset, uint256 swapId) external view returns (int256 payoff);

    function getSOAP(address asset)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

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
