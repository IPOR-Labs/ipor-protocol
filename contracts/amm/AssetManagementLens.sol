// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../interfaces/IAssetManagementLens.sol";
import "../interfaces/IAssetManagement.sol";
import "../interfaces/IStrategy.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";

contract AssetManagementLens is IAssetManagementLens {
    using IporContractValidator for address;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAssetManagement;
    address internal immutable _usdtAmmTreasury;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAssetManagement;
    address internal immutable _usdcAmmTreasury;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAssetManagement;
    address internal immutable _daiAmmTreasury;

    constructor(
        AssetManagementConfiguration memory usdtAssetManagementCfg,
        AssetManagementConfiguration memory usdcAssetManagementCfg,
        AssetManagementConfiguration memory daiAssetManagementCfg
    ) {
        _usdt = usdtAssetManagementCfg.asset.checkAddress();
        _usdtDecimals = usdtAssetManagementCfg.decimals;
        _usdtAssetManagement = usdtAssetManagementCfg.assetManagement.checkAddress();
        _usdtAmmTreasury = usdtAssetManagementCfg.ammTreasury.checkAddress();

        _usdc = usdcAssetManagementCfg.asset.checkAddress();
        _usdcDecimals = usdcAssetManagementCfg.decimals;
        _usdcAssetManagement = usdcAssetManagementCfg.assetManagement.checkAddress();
        _usdcAmmTreasury = usdcAssetManagementCfg.ammTreasury.checkAddress();

        _dai = daiAssetManagementCfg.asset.checkAddress();
        _daiDecimals = daiAssetManagementCfg.decimals;
        _daiAssetManagement = daiAssetManagementCfg.assetManagement.checkAddress();
        _daiAmmTreasury = daiAssetManagementCfg.ammTreasury.checkAddress();
    }

    function balanceOfAmmTreasuryInAssetManagement(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        return IAssetManagement(assetManagementConfiguration.assetManagement).totalBalance();
    }

//    function balanceOfStrategyAave(address asset) external view returns (uint256) {
//        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
//        IAssetManagementInternal assetManagement = IAssetManagementInternal(
//            assetManagementConfiguration.assetManagement
//        );
//        return IStrategy.sol(assetManagement.getStrategyAave()).balanceOf();
//    }
//
//    function balanceOfStrategyCompound(address asset) external view returns (uint256) {
//        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
//        IAssetManagementInternal assetManagement = IAssetManagementInternal(
//            assetManagementConfiguration.assetManagement
//        );
//        return IStrategy.sol(assetManagement.getStrategyCompound()).balanceOf();
//    }

    //TODO: balance of dsr

    function _getAssetManagementConfiguration(
        address asset
    ) internal view returns (AssetManagementConfiguration memory) {
        if (asset == _usdt) {
            return
                AssetManagementConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    assetManagement: _usdtAssetManagement,
                    ammTreasury: _usdtAmmTreasury
                });
        } else if (asset == _usdc) {
            return
                AssetManagementConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    assetManagement: _usdcAssetManagement,
                    ammTreasury: _usdcAmmTreasury
                });
        } else if (asset == _dai) {
            return
                AssetManagementConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    assetManagement: _daiAssetManagement,
                    ammTreasury: _daiAmmTreasury
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}
