// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IAmmGovernanceService.sol";
import "../governance/AmmConfigurationManager.sol";

contract AmmGovernanceService is IAmmGovernanceService {
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) external override {
        AmmConfigurationManager.setAmmAndAssetManagementRatio(asset, newRatio);
    }

    function getAmmAndAssetManagementRatio(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmAndAssetManagementRatio(asset);
    }

    function addSwapLiquidator(address account) external override {
        AmmConfigurationManager.addSwapLiquidator(account);
    }

    function removeSwapLiquidator(address account) external override {
        AmmConfigurationManager.removeSwapLiquidator(account);
    }

    function isSwapLiquidator(address account) external view override returns (bool) {
        return AmmConfigurationManager.isSwapLiquidator(account);
    }
}
