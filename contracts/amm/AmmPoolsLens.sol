// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IAmmPoolsLens.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLens is IAmmPoolsLens {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtIpToken;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcIpToken;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAssetManagement;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiIpToken;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAssetManagement;

    address public immutable iporOracle;

    constructor(
        AmmPoolsLensPoolConfiguration memory usdtPoolCfg,
        AmmPoolsLensPoolConfiguration memory usdcPoolCfg,
        AmmPoolsLensPoolConfiguration memory daiPoolCfg,
        address iporOracleInput
    ) {
        _usdt = usdtPoolCfg.asset.checkAddress();
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtIpToken = usdtPoolCfg.ipToken.checkAddress();
        _usdtAmmStorage = usdtPoolCfg.ammStorage.checkAddress();
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury.checkAddress();
        _usdtAssetManagement = usdtPoolCfg.assetManagement.checkAddress();

        _usdc = usdcPoolCfg.asset.checkAddress();
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcIpToken = usdcPoolCfg.ipToken.checkAddress();
        _usdcAmmStorage = usdcPoolCfg.ammStorage.checkAddress();
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury.checkAddress();
        _usdcAssetManagement = usdcPoolCfg.assetManagement.checkAddress();

        _dai = daiPoolCfg.asset.checkAddress();
        _daiDecimals = daiPoolCfg.decimals;
        _daiIpToken = daiPoolCfg.ipToken.checkAddress();
        _daiAmmStorage = daiPoolCfg.ammStorage.checkAddress();
        _daiAmmTreasury = daiPoolCfg.ammTreasury.checkAddress();
        _daiAssetManagement = daiPoolCfg.assetManagement.checkAddress();

        iporOracle = iporOracleInput.checkAddress();
    }

    function getAmmPoolsLensConfiguration(
        address asset
    ) external view override returns (AmmPoolsLensPoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        return _getPoolCoreModel(asset).getExchangeRate();
    }

    function getAmmBalance(address asset) external view override returns (IporTypes.AmmBalancesMemory memory balance) {
        return _getPoolCoreModel(asset).getAccruedBalance();
    }

    function _getPoolCoreModel(address asset) internal view returns (AmmTypes.AmmPoolCoreModel memory) {
        AmmPoolsLensPoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        AmmTypes.AmmPoolCoreModel memory model;

        model.asset = asset;
        model.assetDecimals = poolCfg.decimals;
        model.ipToken = poolCfg.ipToken;
        model.ammStorage = poolCfg.ammStorage;
        model.ammTreasury = poolCfg.ammTreasury;
        model.assetManagement = poolCfg.assetManagement;
        model.iporOracle = iporOracle;

        return model;
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmPoolsLensPoolConfiguration memory) {
        if (asset == _usdt) {
            return
                AmmPoolsLensPoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ipToken: _usdtIpToken,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement
                });
        } else if (asset == _usdc) {
            return
                AmmPoolsLensPoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ipToken: _usdcIpToken,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement
                });
        } else if (asset == _dai) {
            return
                AmmPoolsLensPoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ipToken: _daiIpToken,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}
