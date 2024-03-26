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
contract AmmGovernanceService is IAmmGovernanceService, IAmmGovernanceLens {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAmmPoolsTreasury;
    address internal immutable _usdtAmmPoolsTreasuryManager;
    address internal immutable _usdtAmmCharlieTreasury;
    address internal immutable _usdtAmmCharlieTreasuryManager;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAmmPoolsTreasury;
    address internal immutable _usdcAmmPoolsTreasuryManager;
    address internal immutable _usdcAmmCharlieTreasury;
    address internal immutable _usdcAmmCharlieTreasuryManager;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAmmPoolsTreasury;
    address internal immutable _daiAmmPoolsTreasuryManager;
    address internal immutable _daiAmmCharlieTreasury;
    address internal immutable _daiAmmCharlieTreasuryManager;

    address internal immutable _stEth;
    uint256 internal immutable _stEthDecimals;
    address internal immutable _stEthAmmStorage;
    address internal immutable _stEthAmmTreasury;
    address internal immutable _stEthAmmPoolsTreasury;
    address internal immutable _stEthAmmPoolsTreasuryManager;
    address internal immutable _stEthAmmCharlieTreasury;
    address internal immutable _stEthAmmCharlieTreasuryManager;

    address internal immutable _weEth;
    uint256 internal immutable _weEthDecimals;
    address internal immutable _weEthAmmStorage;
    address internal immutable _weEthAmmTreasury;
    address internal immutable _weEthAmmPoolsTreasury;
    address internal immutable _weEthAmmPoolsTreasuryManager;
    address internal immutable _weEthAmmCharlieTreasury;
    address internal immutable _weEthAmmCharlieTreasuryManager;

    address internal immutable _usdm;
    uint256 internal immutable _usdmDecimals;
    address internal immutable _usdmAmmStorage;
    address internal immutable _usdmAmmTreasury;
    address internal immutable _usdmAmmPoolsTreasury;
    address internal immutable _usdmAmmPoolsTreasuryManager;
    address internal immutable _usdmAmmCharlieTreasury;
    address internal immutable _usdmAmmCharlieTreasuryManager;

    modifier onlySupportedAssetManagement(address asset) {
        if (asset == _stEth || asset == _weEth || asset == _usdm) {
            revert IporErrors.UnsupportedModule(IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT, asset);
        }
        _;
    }

    constructor(
        AmmGovernancePoolConfiguration memory usdtPoolCfg,
        AmmGovernancePoolConfiguration memory usdcPoolCfg,
        AmmGovernancePoolConfiguration memory daiPoolCfg,
        AmmGovernancePoolConfiguration memory stEthPoolCfg,
        AmmGovernancePoolConfiguration memory weEthPoolCfg,
        AmmGovernancePoolConfiguration memory usdmPoolCfg
    ) {
        _usdt = usdtPoolCfg.asset.checkAddress();
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage.checkAddress();
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury.checkAddress();
        _usdtAmmPoolsTreasury = usdtPoolCfg.ammPoolsTreasury.checkAddress();
        _usdtAmmPoolsTreasuryManager = usdtPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _usdtAmmCharlieTreasury = usdtPoolCfg.ammCharlieTreasury.checkAddress();
        _usdtAmmCharlieTreasuryManager = usdtPoolCfg.ammCharlieTreasuryManager.checkAddress();

        _usdc = usdcPoolCfg.asset.checkAddress();
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage.checkAddress();
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury.checkAddress();
        _usdcAmmPoolsTreasury = usdcPoolCfg.ammPoolsTreasury.checkAddress();
        _usdcAmmPoolsTreasuryManager = usdcPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _usdcAmmCharlieTreasury = usdcPoolCfg.ammCharlieTreasury.checkAddress();
        _usdcAmmCharlieTreasuryManager = usdcPoolCfg.ammCharlieTreasuryManager.checkAddress();

        _dai = daiPoolCfg.asset.checkAddress();
        _daiDecimals = daiPoolCfg.decimals;
        _daiAmmStorage = daiPoolCfg.ammStorage.checkAddress();
        _daiAmmTreasury = daiPoolCfg.ammTreasury.checkAddress();
        _daiAmmPoolsTreasury = daiPoolCfg.ammPoolsTreasury.checkAddress();
        _daiAmmPoolsTreasuryManager = daiPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _daiAmmCharlieTreasury = daiPoolCfg.ammCharlieTreasury.checkAddress();
        _daiAmmCharlieTreasuryManager = daiPoolCfg.ammCharlieTreasuryManager.checkAddress();

        _stEth = stEthPoolCfg.asset.checkAddress();
        _stEthDecimals = stEthPoolCfg.decimals;
        _stEthAmmStorage = stEthPoolCfg.ammStorage.checkAddress();
        _stEthAmmTreasury = stEthPoolCfg.ammTreasury.checkAddress();
        _stEthAmmPoolsTreasury = stEthPoolCfg.ammPoolsTreasury.checkAddress();
        _stEthAmmPoolsTreasuryManager = stEthPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _stEthAmmCharlieTreasury = stEthPoolCfg.ammCharlieTreasury.checkAddress();
        _stEthAmmCharlieTreasuryManager = stEthPoolCfg.ammCharlieTreasuryManager.checkAddress();

        _weEth = weEthPoolCfg.asset.checkAddress();
        _weEthDecimals = weEthPoolCfg.decimals;
        _weEthAmmStorage = weEthPoolCfg.ammStorage.checkAddress();
        _weEthAmmTreasury = weEthPoolCfg.ammTreasury.checkAddress();
        _weEthAmmPoolsTreasury = weEthPoolCfg.ammPoolsTreasury.checkAddress();
        _weEthAmmPoolsTreasuryManager = weEthPoolCfg.ammPoolsTreasuryManager.checkAddress();
        _weEthAmmCharlieTreasury = weEthPoolCfg.ammCharlieTreasury.checkAddress();
        _weEthAmmCharlieTreasuryManager = weEthPoolCfg.ammCharlieTreasuryManager.checkAddress();

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
        if (asset == _usdt) {
            return
                AmmGovernancePoolConfiguration({
                asset: _usdt,
                decimals: _usdtDecimals,
                ammStorage: _usdtAmmStorage,
                ammTreasury: _usdtAmmTreasury,
                ammPoolsTreasury: _usdtAmmPoolsTreasury,
                ammPoolsTreasuryManager: _usdtAmmPoolsTreasuryManager,
                ammCharlieTreasury: _usdtAmmCharlieTreasury,
                ammCharlieTreasuryManager: _usdtAmmCharlieTreasuryManager
            });
        } else if (asset == _usdc) {
            return
                AmmGovernancePoolConfiguration({
                asset: _usdc,
                decimals: _usdcDecimals,
                ammStorage: _usdcAmmStorage,
                ammTreasury: _usdcAmmTreasury,
                ammPoolsTreasury: _usdcAmmPoolsTreasury,
                ammPoolsTreasuryManager: _usdcAmmPoolsTreasuryManager,
                ammCharlieTreasury: _usdcAmmCharlieTreasury,
                ammCharlieTreasuryManager: _usdcAmmCharlieTreasuryManager
            });
        } else if (asset == _dai) {
            return
                AmmGovernancePoolConfiguration({
                asset: _dai,
                decimals: _daiDecimals,
                ammStorage: _daiAmmStorage,
                ammTreasury: _daiAmmTreasury,
                ammPoolsTreasury: _daiAmmPoolsTreasury,
                ammPoolsTreasuryManager: _daiAmmPoolsTreasuryManager,
                ammCharlieTreasury: _daiAmmCharlieTreasury,
                ammCharlieTreasuryManager: _daiAmmCharlieTreasuryManager
            });
        } else if (asset == _stEth) {
            return
                AmmGovernancePoolConfiguration({
                asset: _stEth,
                decimals: _stEthDecimals,
                ammStorage: _stEthAmmStorage,
                ammTreasury: _stEthAmmTreasury,
                ammPoolsTreasury: _stEthAmmPoolsTreasury,
                ammPoolsTreasuryManager: _stEthAmmPoolsTreasuryManager,
                ammCharlieTreasury: _stEthAmmCharlieTreasury,
                ammCharlieTreasuryManager: _stEthAmmCharlieTreasuryManager
            });
        } else if (asset == _weEth) {
            return
                AmmGovernancePoolConfiguration({
                asset: _weEth,
                decimals: _weEthDecimals,
                ammStorage: _weEthAmmStorage,
                ammTreasury: _weEthAmmTreasury,
                ammPoolsTreasury: _weEthAmmPoolsTreasury,
                ammPoolsTreasuryManager: _weEthAmmPoolsTreasuryManager,
                ammCharlieTreasury: _weEthAmmCharlieTreasury,
                ammCharlieTreasuryManager: _weEthAmmCharlieTreasuryManager
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
        if (asset == _usdt) {
            return _usdtAmmTreasury;
        } else if (asset == _usdc) {
            return _usdcAmmTreasury;
        } else if (asset == _dai) {
            return _daiAmmTreasury;
        } else if (asset == _stEth) {
            return _stEthAmmTreasury;
        } else if (asset == _weEth) {
            return _weEthAmmTreasury;
        } else if (asset == _usdm) {
            return _usdmAmmTreasury;
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}
