// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "./types/AmmTypes.sol";

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapServiceStEth {
    /// @notice It opens a swap for stETH pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);

    /// @notice It opens a swap for stETH pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);

    /// @notice It opens a swap for stETH pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);

    /// @notice It opens a swap for stETH receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);

    /// @notice It opens a swap for stETH receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);

    /// @notice It opens a swap for stETH receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable returns (uint256);
}
