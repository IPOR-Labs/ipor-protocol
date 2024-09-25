// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

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
contract AmmGovernanceServiceArbitrum is
    IAmmGovernanceServiceArbitrum,
    IAmmGovernanceService,
    IAmmGovernanceLens,
    IAmmGovernanceLensArbitrum
{
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlySupportedAssetManagement(address asset) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];
        if (poolConfig.ammVault == address(0)) {
            revert IporErrors.UnsupportedModule(IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT, asset);
        }
        _;
    }

    function setMessageSigner(address messageSigner) external override {
        if (messageSigner == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, messageSigner, "messageSigner");
        }
        StorageLibArbitrum.getMessageSignerStorage().value = messageSigner;
    }

    function getMessageSigner() external view override returns (address) {
        return StorageLibArbitrum.getMessageSignerStorage().value;
    }

    function getAssetLensData(
        address asset
    ) external view override returns (StorageLibArbitrum.AssetLensDataValue memory) {
        return StorageLibArbitrum.getAssetLensDataStorage().value[asset];
    }

    function setAssetLensData(
        address asset,
        StorageLibArbitrum.AssetLensDataValue memory assetLensData
    ) external override {
        if (asset == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, asset, "asset");
        }
        StorageLibArbitrum.getAssetLensDataStorage().value[asset] = assetLensData;
    }

    function setAssetServices(
        address asset,
        StorageLibArbitrum.AssetServicesValue memory assetServices
    ) external override {
        if (asset == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, asset, "asset");
        }
        StorageLibArbitrum.getAssetServicesStorage().value[asset] = assetServices;
    }

    function getAssetServices(
        address asset
    ) external view override returns (StorageLibArbitrum.AssetServicesValue memory) {
        return StorageLibArbitrum.getAssetServicesStorage().value[asset];
    }

    function getAmmGovernancePoolConfiguration(
        address asset
    ) external view override returns (AmmGovernancePoolConfiguration memory) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue memory poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];

        return
            AmmGovernancePoolConfiguration({
                asset: asset,
                decimals: poolConfig.decimals,
                ammStorage: poolConfig.ammStorage,
                ammTreasury: poolConfig.ammTreasury,
                ammVault: poolConfig.ammVault,
                ammPoolsTreasury: poolConfig.ammPoolsTreasury,
                ammPoolsTreasuryManager: poolConfig.ammPoolsTreasuryManager,
                ammCharlieTreasury: poolConfig.ammCharlieTreasury,
                ammCharlieTreasuryManager: poolConfig.ammCharlieTreasuryManager
            });
    }

    function setAmmGovernancePoolConfiguration(
        address asset,
        StorageLibArbitrum.AssetGovernancePoolConfigValue calldata assetGovernancePoolConfig
    ) external override {
        if (asset == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, asset, "asset");
        }
        StorageLibArbitrum.getAssetGovernancePoolConfigStorage().value[asset] = assetGovernancePoolConfig;
    }

    function depositToAssetManagement(
        address asset,
        uint256 wadAssetAmount
    ) external override onlySupportedAssetManagement(asset) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];
        IAmmTreasury(poolConfig.ammTreasury).depositToAssetManagementInternal(wadAssetAmount);
    }

    function withdrawFromAssetManagement(
        address asset,
        uint256 wadAssetAmount
    ) external override onlySupportedAssetManagement(asset) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];
        IAmmTreasury(poolConfig.ammTreasury).withdrawFromAssetManagementInternal(wadAssetAmount);
    }

    function withdrawAllFromAssetManagement(address asset) external override onlySupportedAssetManagement(asset) {
        StorageLibArbitrum.AssetGovernancePoolConfigValue storage poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];
        IAmmTreasury(poolConfig.ammTreasury).withdrawAllFromAssetManagementInternal();
    }

    function transferToTreasury(address asset, uint256 wadAssetAmountInput) external override {
        StorageLibArbitrum.AssetGovernancePoolConfigValue memory poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];

        require(msg.sender == poolConfig.ammPoolsTreasuryManager, AmmPoolsErrors.CALLER_NOT_TREASURY_MANAGER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadAssetAmountInput, poolConfig.decimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolConfig.decimals);

        IAmmStorage(poolConfig.ammStorage).updateStorageWhenTransferToTreasuryInternal(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(
            poolConfig.ammTreasury,
            poolConfig.ammPoolsTreasury,
            assetAmountAssetDecimals
        );
    }

    function transferToCharlieTreasury(address asset, uint256 wadAssetAmountInput) external override {
        StorageLibArbitrum.AssetGovernancePoolConfigValue memory poolConfig = StorageLibArbitrum
            .getAssetGovernancePoolConfigStorage()
            .value[asset];

        require(
            msg.sender == poolConfig.ammCharlieTreasuryManager,
            AmmPoolsErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadAssetAmountInput, poolConfig.decimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolConfig.decimals);

        IAmmStorage(poolConfig.ammStorage).updateStorageWhenTransferToCharlieTreasuryInternal(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(
            poolConfig.ammTreasury,
            poolConfig.ammCharlieTreasury,
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
            autoRebalanceThreshold: ammPoolsParamsCfg.autoRebalanceThreshold,
            ammTreasuryAndAssetManagementRatio: ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio
        });
    }
}
