// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../libraries/errors/AmmPoolsErrors.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IAmmGovernanceService.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmStorage.sol";
import "../governance/AmmConfigurationManager.sol";

contract AmmGovernanceService is IAmmGovernanceService {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;

    constructor(
        PoolConfiguration memory usdtPoolCfg,
        PoolConfiguration memory usdcPoolCfg,
        PoolConfiguration memory daiPoolCfg
    ) {
        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.assetDecimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.assetDecimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.assetDecimals;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
    }

    function getAmmGovernanceServicePoolConfiguration(address asset) external view override returns (PoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function depositToAssetManagement(address asset, uint256 assetAmount) external override {
        IAmmTreasury(_getAmmTreasury(asset)).depositToAssetManagement(assetAmount);
    }

    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external override {
        IAmmTreasury(_getAmmTreasury(asset)).withdrawFromAssetManagement(assetAmount);
    }

    function withdrawAllFromAssetManagement(address asset) external override {
        IAmmTreasury(_getAmmTreasury(asset)).withdrawAllFromAssetManagement();
    }

    function transferToTreasury(address asset, uint256 assetAmount) external override {
        require(
            msg.sender == AmmConfigurationManager.getAmmPoolsTreasuryManager(asset),
            AmmPoolsErrors.CALLER_NOT_TREASURY_MANAGER
        );

        address treasury = AmmConfigurationManager.getAmmPoolsTreasury(asset);

        require(address(0) != treasury, AmmPoolsErrors.INCORRECT_TREASURE_TREASURER);

        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, poolCfg.assetDecimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.assetDecimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToTreasury(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(poolCfg.ammTreasury, treasury, assetAmountAssetDecimals);
    }

    function transferToCharlieTreasury(address asset, uint256 assetAmount) external override {
        require(
            msg.sender == AmmConfigurationManager.getAmmCharlieTreasuryManager(asset),
            AmmPoolsErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );

        address charlieTreasury = AmmConfigurationManager.getAmmCharlieTreasury(asset);

        require(address(0) != charlieTreasury, AmmPoolsErrors.INCORRECT_CHARLIE_TREASURER);

        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, poolCfg.assetDecimals);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.assetDecimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToCharlieTreasury(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(poolCfg.ammTreasury, charlieTreasury, assetAmountAssetDecimals);
    }

    function addSwapLiquidator(address asset, address account) external override {
        AmmConfigurationManager.addSwapLiquidator(asset, account);
    }

    function removeSwapLiquidator(address asset, address account) external override {
        AmmConfigurationManager.removeSwapLiquidator(asset, account);
    }

    function isSwapLiquidator(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isSwapLiquidator(asset, account);
    }

    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) external override {
        AmmConfigurationManager.setAmmAndAssetManagementRatio(asset, newRatio);
    }

    function getAmmAndAssetManagementRatio(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmAndAssetManagementRatio(asset);
    }

    function setAmmMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) external override {
        AmmConfigurationManager.setAmmMaxLiquidityPoolBalance(asset, newMaxLiquidityPoolBalance);
    }

    function getAmmMaxLiquidityPoolBalance(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmMaxLiquidityPoolBalance(asset);
    }

    function setAmmMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) external override {
        AmmConfigurationManager.setAmmMaxLpAccountContribution(asset, newMaxLpAccountContribution);
    }

    function getAmmMaxLpAccountContribution(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmMaxLpAccountContribution(asset);
    }

    function addAppointedToRebalanceInAmm(address asset, address account) external override {
        AmmConfigurationManager.addAppointedToRebalanceInAmm(asset, account);
    }

    function removeAppointedToRebalanceInAmm(address asset, address account) external override {
        AmmConfigurationManager.removeAppointedToRebalanceInAmm(asset, account);
    }

    function isAppointedToRebalanceInAmm(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isAppointedToRebalanceInAmm(asset, account);
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

    function setAmmCharlieTreasury(address asset, address newCharlieTreasuryWallet) external override {
        AmmConfigurationManager.setAmmCharlieTreasury(asset, newCharlieTreasuryWallet);
    }

    function getAmmCharlieTreasury(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmCharlieTreasury(asset);
    }

    function setAmmCharlieTreasuryManager(address asset, address newCharlieTreasuryManager) external override {
        AmmConfigurationManager.setAmmCharlieTreasuryManager(asset, newCharlieTreasuryManager);
    }

    function getAmmCharlieTreasuryManager(address asset) external view override returns (address) {
        return AmmConfigurationManager.getAmmCharlieTreasuryManager(asset);
    }

    function setAmmAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) external override {
        AmmConfigurationManager.setAmmAutoRebalanceThreshold(asset, newAutoRebalanceThreshold);
    }

    function getAmmAutoRebalanceThreshold(address asset) external view override returns (uint256) {
        return AmmConfigurationManager.getAmmAutoRebalanceThreshold(asset);
    }

    function _getPoolConfiguration(address asset) internal view returns (PoolConfiguration memory) {
        if (asset == _usdt) {
            return
                PoolConfiguration({
                    asset: _usdt,
                    assetDecimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury
                });
        } else if (asset == _usdc) {
            return
                PoolConfiguration({
                    asset: _usdc,
                    assetDecimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury
                });
        } else if (asset == _dai) {
            return
                PoolConfiguration({
                    asset: _dai,
                    assetDecimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury
                });
        } else {
            revert("Asset not supported");
        }
    }

    function _getAmmTreasury(address asset) internal view returns (address) {
        if (asset == _usdt) {
            return _usdtAmmTreasury;
        } else if (asset == _usdc) {
            return _usdcAmmTreasury;
        } else if (asset == _dai) {
            return _daiAmmTreasury;
        } else {
            revert("Asset not supported");
        }
    }
}
