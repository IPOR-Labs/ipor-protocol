// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/IAmmTreasury.sol";
import "../../../interfaces/IAmmStorage.sol";
import "../../../interfaces/IAmmGovernanceService.sol";
import "../../../interfaces/IAmmGovernanceLens.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/errors/AmmPoolsErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../governance/AmmConfigurationManager.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";
import {IAmmGovernanceServiceArbitrum} from "../interfaces/IAmmGovernanceServiceArbitrum.sol";
import {IAmmGovernanceLensArbitrum} from "../interfaces/IAmmGovernanceLensArbitrum.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmGovernanceServiceArbitrum is IAmmGovernanceServiceArbitrum, IAmmGovernanceService, IAmmGovernanceLens, IAmmGovernanceLensArbitrum {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlySupportedAssetManagement(address asset) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum.getAssetGovernancePoolConfigStorage().value[asset];
        if (poolConfig.vault == address(0)) {
            revert IporErrors.UnsupportedModule(IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT, asset);
        }
        _;
    }

    function setIporIndexOracle(address asset, address iporIndexOracle) external override {
        StorageLibArbitrum.getIporIndexOracleStorage().value = iporIndexOracle;
    }

    function getIporIndexOracle(address asset) external override view returns (address) {
        return StorageLibArbitrum.getIporIndexOracleStorage().value;
    }

    function setMessageSigner(address messageSigner) external override {
        StorageLibArbitrum.getMessageSignerStorage().value = messageSigner;
    }

    function getMessageSigner() external view override returns (address) {
        return StorageLibArbitrum.getMessageSignerStorage().value;
    }

    function getAssetLensData(address asset) external override view returns (StorageLibArbitrum.AssetLensDataValue memory) {
        return StorageLibArbitrum.getAssetLensDataStorage().value[asset];
    }

    function setAssetLensData(address asset, StorageLibArbitrum.AssetLensDataValue memory assetLensData) external override {
        StorageLibArbitrum.getAssetLensDataStorage().value[asset] = assetLensData;
    }

    function setAssetServices(address asset, StorageLibArbitrum.AssetServicesValue memory assetServices) external override {
        StorageLibArbitrum.getAssetServicesStorage().value[asset] = assetServices;
    }

    function getAssetServices(address asset) external override view returns (StorageLibArbitrum.AssetServicesValue memory) {
        return StorageLibArbitrum.getAssetServicesStorage().value[asset];
    }

    function getAmmGovernancePoolConfiguration(
        address asset_
    ) external view override returns (AmmGovernancePoolConfiguration memory) {
        return _getPoolConfiguration(asset_);
    }

    function setAmmGovernancePoolConfiguration(
        address asset,
        StorageLibArbitrum.AssetGovernancePoolConfigValue calldata assetGovernancePoolConfig
    ) external override {
        StorageLibArbitrum.getAssetGovernancePoolConfigStorage().value[asset] = assetGovernancePoolConfig;
    }

    function depositToAssetManagement(
        address asset,
        uint256 wadAssetAmount
    ) external override onlySupportedAssetManagement(asset) {
        IAmmTreasury(_getAmmTreasury(asset)).depositToAssetManagementInternal(wadAssetAmount);
    }

    function withdrawFromAssetManagement(
        address asset,
        uint256 wadAssetAmount
    ) external override onlySupportedAssetManagement(asset) {
        IAmmTreasury(_getAmmTreasury(asset)).withdrawFromAssetManagementInternal(wadAssetAmount);
    }

    function withdrawAllFromAssetManagement(address asset) external override onlySupportedAssetManagement(asset) {
        IAmmTreasury(_getAmmTreasury(asset)).withdrawAllFromAssetManagementInternal();
    }

    function transferToTreasury(address asset, uint256 wadAssetAmountInput) external override {
        AmmGovernancePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        require(msg.sender == poolCfg.ammPoolsTreasuryManager, AmmPoolsErrors.CALLER_NOT_TREASURY_MANAGER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadAssetAmountInput, poolCfg.decimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.decimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToTreasuryInternal(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(
            poolCfg.ammTreasury,
            poolCfg.ammPoolsTreasury,
            assetAmountAssetDecimals
        );
    }

    function transferToCharlieTreasury(address asset, uint256 wadAssetAmountInput) external override {
        AmmGovernancePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        require(msg.sender == poolCfg.ammCharlieTreasuryManager, AmmPoolsErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadAssetAmountInput, poolCfg.decimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.decimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToCharlieTreasuryInternal(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(
            poolCfg.ammTreasury,
            poolCfg.ammCharlieTreasury,
            assetAmountAssetDecimals
        );
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

    function addAppointedToRebalanceInAmm(
        address asset,
        address account
    ) external override onlySupportedAssetManagement(asset) {
        AmmConfigurationManager.addAppointedToRebalanceInAmm(asset, account);
    }

    function removeAppointedToRebalanceInAmm(
        address asset,
        address account
    ) external override onlySupportedAssetManagement(asset) {
        AmmConfigurationManager.removeAppointedToRebalanceInAmm(asset, account);
    }

    function isAppointedToRebalanceInAmm(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isAppointedToRebalanceInAmm(asset, account);
    }

    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newAutoRebalanceThreshold,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external override {
        AmmConfigurationManager.setAmmPoolsParams(
            asset,
            newMaxLiquidityPoolBalance,
            newAutoRebalanceThreshold,
            newAmmTreasuryAndAssetManagementRatio
        );
    }

    function getAmmPoolsParams(address asset) external view override returns (AmmPoolsParamsConfiguration memory cfg) {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(asset);
        cfg = AmmPoolsParamsConfiguration({
            maxLiquidityPoolBalance: uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            autoRebalanceThresholdInThousands: ammPoolsParamsCfg.autoRebalanceThresholdInThousands,
            ammTreasuryAndAssetManagementRatio: ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio
        });
    }

    function _getPoolConfiguration(address asset_) internal view returns (AmmGovernancePoolConfiguration memory) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue memory poolConfig = StorageLibArbitrum.getAssetGovernancePoolConfigStorage().value[asset_];

        return AmmGovernancePoolConfiguration({
            asset: asset_,
            decimals: poolConfig.decimals,
            ammStorage: poolConfig.ammStorage,
            ammTreasury: poolConfig.ammTreasury,
            ammPoolsTreasury: poolConfig.ammPoolsTreasury,
            ammPoolsTreasuryManager: poolConfig.ammPoolsTreasuryManager,
            ammCharlieTreasury: poolConfig.ammCharlieTreasury,
            ammCharlieTreasuryManager: poolConfig.ammCharlieTreasuryManager
        });
    }

    function _getAmmTreasury(address asset) internal view returns (address) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum.getAssetGovernancePoolConfigStorage().value[asset];
        return poolConfig.ammTreasury;
    }
}
