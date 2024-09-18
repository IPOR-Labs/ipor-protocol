// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {AmmTypes} from "../../../interfaces/types/AmmTypes.sol";

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapServiceDai {
    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for USDC pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for USDC receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param totalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);
}
