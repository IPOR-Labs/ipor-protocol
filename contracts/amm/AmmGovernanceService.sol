// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IAmmGovernanceService.sol";
import "../governance/AmmConfigurationManager.sol";

contract AmmGovernanceService is IAmmGovernanceService {
    function addSwapLiquidator(address asset, address account) external override {
        AmmConfigurationManager.addSwapLiquidator(asset, account);
    }

    function removeSwapLiquidator(address asset, address account) external override {
        AmmConfigurationManager.removeSwapLiquidator(asset, account);
    }

    function isSwapLiquidator(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isSwapLiquidator(asset, account);
    }

    function setAmmPoolsAndAssetManagementRatio(address asset, uint256 newRatio) external override {
        AmmConfigurationManager.setAmmPoolsAndAssetManagementRatio(asset, newRatio);
    }

    function getAmmPoolsAndAssetManagementRatio(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmPoolsAndAssetManagementRatio(asset);
    }

    function setAmmPoolsMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) external override {
        AmmConfigurationManager.setAmmPoolsMaxLiquidityPoolBalance(asset, newMaxLiquidityPoolBalance);
    }

    function getAmmPoolsMaxLiquidityPoolBalance(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmPoolsMaxLiquidityPoolBalance(asset);
    }

    function setAmmPoolsMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) external override {
        AmmConfigurationManager.setAmmPoolsMaxLpAccountContribution(asset, newMaxLpAccountContribution);
    }

    function getAmmPoolsMaxLpAccountContribution(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmPoolsMaxLpAccountContribution(asset);
    }

    function addAmmPoolsAppointedToRebalance(address asset, address account) external override {
        AmmConfigurationManager.addAmmPoolsAppointedToRebalance(asset, account);
    }

    function removeAmmPoolsAppointedToRebalance(address asset, address account) external override {
        AmmConfigurationManager.removeAmmPoolsAppointedToRebalance(asset, account);
    }

    function isAmmPoolsAppointedToRebalance(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isAmmPoolsAppointedToRebalance(asset, account);
    }

    function setAmmPoolsTreasury(address asset, address newTreasuryWallet) external override {
        AmmConfigurationManager.setAmmPoolsTreasury(asset, newTreasuryWallet);
    }

    function getAmmPoolsTreasury(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmPoolsTreasury(asset);
    }

    function setAmmPoolsTreasuryManager(address asset, address newTreasuryManager) external override {
        AmmConfigurationManager.setAmmPoolsTreasuryManager(asset, newTreasuryManager);
    }

    function getAmmPoolsTreasuryManager(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmPoolsTreasuryManager(asset);
    }

    function setAmmPoolsCharlieTreasury(address asset, address newCharlieTreasuryWallet) external override {
        AmmConfigurationManager.setAmmPoolsCharlieTreasury(asset, newCharlieTreasuryWallet);
    }

    function getAmmPoolsCharlieTreasury(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmPoolsCharlieTreasury(asset);
    }

    function setAmmPoolsCharlieTreasuryManager(address asset, address newCharlieTreasuryManager) external override {
        AmmConfigurationManager.setAmmPoolsCharlieTreasuryManager(asset, newCharlieTreasuryManager);
    }

    function getAmmPoolsCharlieTreasuryManager(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmPoolsCharlieTreasuryManager(asset);
    }

    function setAmmPoolsAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) external override {
        AmmConfigurationManager.setAmmPoolsAutoRebalanceThreshold(asset, newAutoRebalanceThreshold);
    }

    function getAmmPoolsAutoRebalanceThreshold(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmPoolsAutoRebalanceThreshold(asset);
    }
}
