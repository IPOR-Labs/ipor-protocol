// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/errors/JosephErrors.sol";
import "../libraries/StorageLib.sol";

library AmmConfigurationManager {
    /// @dev key - asset address, value - ratio
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) internal {
        require(newRatio > 0, JosephErrors.MILTON_STANLEY_RATIO);
        require(newRatio < 1e18, JosephErrors.MILTON_STANLEY_RATIO);
        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        ratio[asset] = newRatio;
    }

    function getAmmAndAssetManagementRatio(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        return ratio[asset];
    }

    function addSwapLiquidator(address account) internal {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        swapLiquidators[account] = true;
    }

    function removeSwapLiquidator(address account) internal {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        swapLiquidators[account] = false;
    }

    function isSwapLiquidator(address account) internal view returns (bool) {
        mapping(address => bool) storage swapLiquidators = StorageLib.getAmmSwapLiquidatorsStorage();
        return swapLiquidators[account];
    }
}
