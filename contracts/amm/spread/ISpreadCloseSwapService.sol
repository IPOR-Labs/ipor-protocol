// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/amm/libraries/types/AmmInternalTypes.sol";
import "contracts/amm/spread/SpreadTypes.sol";

interface ISpreadCloseSwapService {
    /// @notice Updates the time-weighted notional on swap closure.
    /// @dev Updates the time-weighted notional for the specified asset and tenor based on the swap closure.
    /// @param asset The address of the asset involved in the swap.
    /// @param direction The direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed.
    /// @param tenor The tenor of the swap.
    /// @param swapNotional The notional amount of the swap.
    /// @param closedSwap The memory struct containing the swap information.
    /// @param ammStorageAddress The address of the AMM storage.
    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external;
}
