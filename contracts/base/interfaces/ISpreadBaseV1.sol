// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";
import "../../amm/libraries/types/AmmInternalTypes.sol";
import "../types/SpreadTypesBaseV1.sol";

interface ISpreadBaseV1 {
    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT/stETH/etc.
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        /// @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
    }

    /// @notice Calculates and updates the offered rate for Pay Fixed leg of a swap.
    /// @dev This function should be called only through the Router contract as per the 'onlyRouter' modifier.
    ///      It calculates the offered rate for Pay Fixed swaps by taking into account various factors like
    ///      IPOR index value, base spread, demand spread, and rate cap.
    ///      The demand spread is updated based on the current market conditions and the swap's specifics.
    /// @param spreadInputs A 'SpreadInputs' struct containing all necessary data for calculating the offered rate.
    ///                     This includes the asset's address, swap's notional value, demand spread factor, base spread,
    ///                     balances for Pay Fixed and Receive Fixed legs, liquidity pool balance, IPOR index value at swap creation,
    ///                     fixed rate cap per leg, and the swap's tenor.
    /// @return offeredRate The calculated offered rate for the Pay Fixed leg in the swap.
    function calculateAndUpdateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external returns (uint256 offeredRate);

    /// @notice Calculates the offered rate for a swap based on the specified direction (Pay Fixed or Receive Fixed).
    /// @dev This function computes the offered rate for a swap, taking into account the swap's direction,
    ///      the current IPOR index value, base spread, demand spread, and the fixed rate cap.
    ///      It is a view function and does not modify the state of the contract.
    /// @param direction An enum value from 'AmmTypes' specifying the swap direction -
    ///                  either PAY_FIXED_RECEIVE_FLOATING or PAY_FLOATING_RECEIVE_FIXED.
    /// @param spreadInputs A 'SpreadInputs' struct containing necessary data for calculating the offered rate,
    ///                     such as the asset's address, swap's notional value, demand spread factor, base spread,
    ///                     balances for Pay Fixed and Receive Fixed legs, liquidity pool balance, IPOR index value at the time of swap creation,
    ///                     fixed rate cap per leg, and the swap's tenor.
    /// @return The calculated offered rate for the specified swap direction.
    ///         The rate is returned as a uint256.
    function calculateOfferedRate(
        AmmTypes.SwapDirection direction,
        SpreadInputs calldata spreadInputs
    ) external view returns (uint256);

    /// @notice Calculates the offered rate for a Pay Fixed swap.
    /// @dev This view function computes the offered rate specifically for swaps where the Pay Fixed leg is chosen.
    ///      It considers various inputs like the IPOR index value, base spread, demand spread, and the fixed rate cap
    ///      to determine the appropriate rate. As a view function, it does not alter the state of the contract.
    /// @param spreadInputs A 'SpreadInputs' struct containing data essential for calculating the offered rate.
    ///                     This includes information such as the asset's address, the notional value of the swap,
    ///                     the demand spread factor, the base spread, balances of Pay Fixed and Receive Fixed legs,
    ///                     the liquidity pool balance, the IPOR index value at the time of swap creation, the fixed rate cap per leg,
    ///                     and the swap's tenor.
    /// @return offeredRate The calculated offered rate for the Pay Fixed leg of the swap, returned as a uint256.
    function calculateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external view returns (uint256 offeredRate);

    /// @notice Calculates and updates the offered rate for the Receive Fixed leg of a swap.
    /// @dev This function is accessible only through the Router contract, as enforced by the 'onlyRouter' modifier.
    ///      It calculates the offered rate for Receive Fixed swaps, considering various factors like the IPOR index value,
    ///      base spread, imbalance spread, and the fixed rate cap. This function also updates the time-weighted notional
    ///      based on the current market conditions and the specifics of the swap.
    /// @param spreadInputs A 'SpreadInputs' struct containing all necessary data for calculating the offered rate.
    ///                     This includes the asset's address, swap's notional value, demand spread factor, base spread,
    ///                     balances for Pay Fixed and Receive Fixed legs, liquidity pool balance, IPOR index value at swap creation,
    ///                     fixed rate cap per leg, and the swap's tenor.
    /// @return offeredRate The calculated offered rate for the Receive Fixed leg in the swap, returned as a uint256.
    function calculateAndUpdateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external returns (uint256 offeredRate);

    /// @notice Calculates the offered rate for a Receive Fixed swap.
    /// @dev This view function computes the offered rate specifically for swaps where the Receive Fixed leg is chosen.
    ///      It evaluates various inputs such as the IPOR index value, base spread, demand spread, and the fixed rate cap
    ///      to determine the appropriate rate. Being a view function, it does not modify the state of the contract.
    /// @param spreadInputs A 'SpreadInputs' struct containing the necessary data for calculating the offered rate.
    ///                     This includes the asset's address, swap's notional value, demand spread factor, base spread,
    ///                     balances for Pay Fixed and Receive Fixed legs, liquidity pool balance, the IPOR index value at the time of swap creation,
    ///                     fixed rate cap per leg, and the swap's tenor.
    /// @return offeredRate The calculated offered rate for the Receive Fixed leg of the swap, returned as a uint256.
    function calculateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external view returns (uint256 offeredRate);

    /// @notice Updates the time-weighted notional values when a swap is closed.
    /// @dev This function is called upon the closure of a swap to adjust the time-weighted notional values for Pay Fixed
    ///      or Receive Fixed legs, reflecting the change in the market conditions due to the closed swap.
    ///      It takes into account the swap's direction, tenor, notional, and the details of the closed swap to make the necessary adjustments.
    /// @param direction A uint256 indicating the direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed.
    /// @param tenor The tenor of the swap, represented by an enum value from 'IporTypes'.
    /// @param swapNotional The notional value of the swap that is being closed.
    /// @param closedSwap An 'OpenSwapItem' struct from 'AmmInternalTypes' representing the details of the swap that was closed.
    /// @param ammStorageAddress The address of the AMM (Automated Market Maker) storage contract where the swap data is maintained.
    /// @dev This function should only be called by an authorized Router, as it can significantly impact the contract's state.
    function updateTimeWeightedNotionalOnClose(
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external;

    /// @notice Retrieves time-weighted notional values for various asset-tenor pairs.
    /// @dev Returns an array of `TimeWeightedNotionalResponse` containing time-weighted notional values and associated keys.
    /// @return timeWeightedNotionalResponse An array of `TimeWeightedNotionalResponse` structures, each including a time-weighted notional value and a corresponding key.
    function getTimeWeightedNotional()
        external
        view
        returns (SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse);

    /// @notice Retrieves the configuration parameters for the spread function.
    /// @dev This function provides access to the current configuration of the spread function used in the contract.
    ///      It returns an array of uint256 values, each representing a specific parameter or threshold used in
    ///      the calculation of spreads for different swap legs or conditions.
    /// @return An array of uint256 values representing the configuration parameters of the spread function.
    ///      These parameters are critical in determining how spreads are calculated for Pay Fixed and Receive Fixed swaps.
    function spreadFunctionConfig() external returns (uint256[] memory);

    /// @notice Updates the time-weighted notional values for multiple assets and tenors.
    /// @dev This function can only be called by the contract owner and overrides any existing implementation.
    ///     It iterates through an array of `TimeWeightedNotionalMemory` structures, checks each one for validity,
    ///     and then saves the updated time-weighted notional values.
    /// @param timeWeightedNotionalMemories An array of `TimeWeightedNotionalMemory` structures, where each structure
    ///        contains information about the asset, tenor, and the new time-weighted notional value to be updated.
    ///        Each `TimeWeightedNotionalMemory` structure should have a `storageId` identifying the asset and tenor
    ///        combination, along with the notional values and other relevant information.
    /// @dev The function employs an `unchecked` block for the loop iteration to optimize gas usage, assuming that
    ///         the arithmetic operation will not overflow under normal operation conditions.
    function updateTimeWeightedNotional(
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[] calldata timeWeightedNotionalMemories
    ) external;

    /// @notice Returns the version number of the contract.
    /// @dev This function provides a simple way to retrieve the version number of the current contract.
    ///      It's useful for compatibility checks, upgradeability assessments, and tracking contract iterations.
    ///      The version number is returned as a uint256.
    /// @return A uint256 value representing the version number of the contract.
    function getVersion() external pure returns (uint256);
}
