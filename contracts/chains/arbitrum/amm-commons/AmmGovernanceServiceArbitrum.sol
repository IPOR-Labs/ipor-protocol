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

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmGovernanceServiceArbitrum is IAmmGovernanceService, IAmmGovernanceLens {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _wstEth;
    uint256 internal immutable _wstEthDecimals;
    address internal immutable _wstEthAmmStorage;
    address internal immutable _wstEthAmmTreasury;
    address internal immutable _wstEthAmmPoolsTreasury;
    address internal immutable _wstEthAmmPoolsTreasuryManager;
    address internal immutable _wstEthAmmCharlieTreasury;
    address internal immutable _wstEthAmmCharlieTreasuryManager;

    address internal immutable _usdm;
    uint256 internal immutable _usdmDecimals;
    address internal immutable _usdmAmmStorage;
    address internal immutable _usdmAmmTreasury;
    address internal immutable _usdmAmmPoolsTreasury;
    address internal immutable _usdmAmmPoolsTreasuryManager;
    address internal immutable _usdmAmmCharlieTreasury;
    address internal immutable _usdmAmmCharlieTreasuryManager;

    modifier onlySupportedAssetManagement(address asset) {
        if (asset == _wstEth || asset == _usdm) {
            revert IporErrors.UnsupportedModule(IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT, asset);
        }
        _;
    }

    constructor(
        AmmGovernancePoolConfiguration memory wstEthPoolCfg,
        AmmGovernancePoolConfiguration memory usdmPoolCfg
    ) {
        _wstEth = wstEthPoolCfg.asset.checkAddress();
        _wstEthDecimals = wstEthPoolCfg.decimals;
        _wstEthAmmStorage = wstEthPoolCfg.ammStorage.checkAddress();
        _wstEthAmmTreasury = wstEthPoolCfg.ammTreasury.checkAddress();
        _wstEthAmmPoolsTreasury = wstEthPoolCfg.ammPoolsTreasury.checkAddress();
        _wstEthAmmPoolsTreasuryManager = wstEthPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _wstEthAmmCharlieTreasury = wstEthPoolCfg.ammCharlieTreasury.checkAddress();
        _wstEthAmmCharlieTreasuryManager = wstEthPoolCfg.ammCharlieTreasuryManager.checkAddress();

        _usdm = usdmPoolCfg.asset.checkAddress();
        _usdmDecimals = usdmPoolCfg.decimals;
        _usdmAmmStorage = usdmPoolCfg.ammStorage.checkAddress();
        _usdmAmmTreasury = usdmPoolCfg.ammTreasury.checkAddress();
        _usdmAmmPoolsTreasury = usdmPoolCfg.ammPoolsTreasury.checkAddress();
        _usdmAmmPoolsTreasuryManager = usdmPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _usdmAmmCharlieTreasury = usdmPoolCfg.ammCharlieTreasury.checkAddress();
        _usdmAmmCharlieTreasuryManager = usdmPoolCfg.ammCharlieTreasuryManager.checkAddress();
    }

    function getAmmGovernancePoolConfiguration(
        address asset
    ) external view override returns (AmmGovernancePoolConfiguration memory) {
        return _getPoolConfiguration(asset);
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

    function _getPoolConfiguration(address asset) internal view returns (AmmGovernancePoolConfiguration memory) {
        if (asset == _wstEth) {
            return
                AmmGovernancePoolConfiguration({
                    asset: _wstEth,
                    decimals: _wstEthDecimals,
                    ammStorage: _wstEthAmmStorage,
                    ammTreasury: _wstEthAmmTreasury,
                    ammPoolsTreasury: _wstEthAmmPoolsTreasury,
                    ammPoolsTreasuryManager: _wstEthAmmPoolsTreasuryManager,
                    ammCharlieTreasury: _wstEthAmmCharlieTreasury,
                    ammCharlieTreasuryManager: _wstEthAmmCharlieTreasuryManager
                });
        } else if (asset == _usdm) {
            return
                AmmGovernancePoolConfiguration({
                    asset: _usdm,
                    decimals: _usdmDecimals,
                    ammStorage: _usdmAmmStorage,
                    ammTreasury: _usdmAmmTreasury,
                    ammPoolsTreasury: _usdmAmmPoolsTreasury,
                    ammPoolsTreasuryManager: _usdmAmmPoolsTreasuryManager,
                    ammCharlieTreasury: _usdmAmmCharlieTreasury,
                    ammCharlieTreasuryManager: _usdmAmmCharlieTreasuryManager
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }

    function _getAmmTreasury(address asset) internal view returns (address) {
        if (asset == _wstEth) {
            return _wstEthAmmTreasury;
        } else if (asset == _usdm) {
            return _usdmAmmTreasury;
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}
