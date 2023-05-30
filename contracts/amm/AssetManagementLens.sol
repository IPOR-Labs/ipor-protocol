// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/errors/IporErrors.sol";
import "../interfaces/IAssetManagementLens.sol";
import "../interfaces/IAssetManagement.sol";
import "../interfaces/IAssetManagementInternal.sol";
import "../interfaces/IStrategy.sol";

contract AssetManagementLens is IAssetManagementLens {
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
        require(
            usdtAssetManagementCfg.asset != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT AssetManagement asset")
        );
        require(
            usdtAssetManagementCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT AssetManagement asset")
        );
        require(
            usdtAssetManagementCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT AmmTreasury asset")
        );

        require(
            usdcAssetManagementCfg.asset != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC AssetManagement asset")
        );
        require(
            usdcAssetManagementCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC AssetManagement asset")
        );
        require(
            usdcAssetManagementCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC AmmTreasury asset")
        );

        require(
            daiAssetManagementCfg.asset != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI AssetManagement asset")
        );
        require(
            daiAssetManagementCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI AssetManagement asset")
        );
        require(
            daiAssetManagementCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI AmmTreasury asset")
        );

        _usdt = usdtAssetManagementCfg.asset;
        _usdtDecimals = usdtAssetManagementCfg.decimals;
        _usdtAssetManagement = usdtAssetManagementCfg.assetManagement;
        _usdtAmmTreasury = usdtAssetManagementCfg.ammTreasury;

        _usdc = usdcAssetManagementCfg.asset;
        _usdcDecimals = usdcAssetManagementCfg.decimals;
        _usdcAssetManagement = usdcAssetManagementCfg.assetManagement;
        _usdcAmmTreasury = usdcAssetManagementCfg.ammTreasury;

        _dai = daiAssetManagementCfg.asset;
        _daiDecimals = daiAssetManagementCfg.decimals;
        _daiAssetManagement = daiAssetManagementCfg.assetManagement;
        _daiAmmTreasury = daiAssetManagementCfg.ammTreasury;
    }

    function balanceOfAmmTreasuryInAssetManagement(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        return IAssetManagement(assetManagementConfiguration.assetManagement).totalBalance(assetManagementConfiguration.ammTreasury);
    }

    function getIvTokenExchangeRate(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        return IAssetManagement(assetManagementConfiguration.assetManagement).calculateExchangeRate();
    }

    function aaveBalanceOfInAssetManagement(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        IAssetManagementInternal assetManagement = IAssetManagementInternal(assetManagementConfiguration.assetManagement);
        return IStrategy(assetManagement.getStrategyAave()).balanceOf();
    }

    function compoundBalanceOfInAssetManagement(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        IAssetManagementInternal assetManagement = IAssetManagementInternal(assetManagementConfiguration.assetManagement);
        return IStrategy(assetManagement.getStrategyCompound()).balanceOf();
    }

    function _getAssetManagementConfiguration(address asset)
        internal
        view
        returns (AssetManagementConfiguration memory)
    {
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
            revert("AssetManagementsLens: asset not supported");
        }
    }
}
