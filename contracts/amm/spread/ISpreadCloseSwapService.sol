// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./SpreadTypes.sol";
import "../libraries/types/AmmInternalTypes.sol";
import "../../interfaces/types/AmmTypes.sol";

interface ISpreadCloseSwapService {
    /// @notice Updates the time-weighted notional on swap closure.
    /// @dev Updates the time-weighted notional for the specified asset and maturity based on the swap closure.
    /// @param asset The address of the asset involved in the swap.
    /// @param direction The direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed.
    /// @param duration of swap.
    /// @param swapNotional The notional amount of the swap.
    /// @param closedSwap The memory struct containing the swap information.
    /// @param ammStorageAddress The address of the AMM storage.
    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        AmmTypes.SwapDuration duration,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external;
}
