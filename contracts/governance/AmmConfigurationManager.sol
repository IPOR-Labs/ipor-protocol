// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/errors/JosephErrors.sol";
import "../libraries/StorageLib.sol";

library AmmConfigurationManager {
    /// @notice Emitted when new ratio AMM vs Asset Management is set for asset.
    /// @param asset address of the asset
    /// @param ratio new ratio, describe what percentage of asset should be managed by AMM against Asset Management.
    event AmmAndAssetManagementRatioSet(address indexed asset, uint256 ratio);

    /// @notice Emitted when new liquidator is added to the list of SwapLiquidators.
    /// @param liquidator address of the new liquidator
    event SwapLiquidatorAdded(address indexed liquidator);

    /// @notice Emitted when liquidator is removed from the list of SwapLiquidators.
    /// @param liquidator address of the liquidator
    event SwapLiquidatorRemoved(address indexed liquidator);

    /// @dev key - asset address, value - ratio
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) internal {
        require(newRatio > 0, JosephErrors.MILTON_STANLEY_RATIO);
        require(newRatio < 1e18, JosephErrors.MILTON_STANLEY_RATIO);
        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        ratio[asset] = newRatio;
        emit AmmAndAssetManagementRatioSet(asset, newRatio);
    }

    function getAmmAndAssetManagementRatio(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        return ratio[asset];
    }

    function addSwapLiquidator(address account) internal {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        swapLiquidators[account] = true;
        emit SwapLiquidatorAdded(account);
    }

    function removeSwapLiquidator(address account) internal {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        swapLiquidators[account] = false;
        emit SwapLiquidatorRemoved(account);
    }

    function isSwapLiquidator(address account) internal view returns (bool) {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        return swapLiquidators[account];
    }
}
