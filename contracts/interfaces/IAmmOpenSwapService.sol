// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/AmmTypes.sol";

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapService {
    /// @notice Emitted when the trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction, Pay Fixed Receive Floating or Pay Floating Receive Fixed.
        AmmTypes.SwapDirection direction,
        /// @notice technical structure with amounts related with this swap
        AmmTypes.OpenSwapAmount amounts,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice specific indicators related with this swap
        AmmTypes.IporSwapIndicator indicator
    );

    /// @notice It opens a swap for USDT pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDT pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDT pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDT receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDT receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDT receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice It opens a swap for DAI receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount used by sender to open the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);
}
