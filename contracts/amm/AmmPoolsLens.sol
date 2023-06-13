// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/errors/IporErrors.sol";
import "../libraries/AmmLib.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IAmmPoolsLens.sol";

contract AmmPoolsLens is IAmmPoolsLens {
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

    address internal immutable _iporOracle;

    constructor(
        AmmPoolsLensPoolConfiguration memory usdtPoolCfg,
        AmmPoolsLensPoolConfiguration memory usdcPoolCfg,
        AmmPoolsLensPoolConfiguration memory daiPoolCfg,
        address iporOracle
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool asset address cannot be 0"));
        require(usdtPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ipToken address cannot be 0"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammStorage address cannot be 0"));
        require(
            usdtPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammTreasury address cannot be 0")
        );
        require(
            usdtPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool assetManagement address cannot be 0")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool asset address cannot be 0"));
        require(usdcPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ipToken address cannot be 0"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammStorage address cannot be 0"));
        require(
            usdcPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammTreasury address cannot be 0")
        );
        require(
            usdcPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool assetManagement address cannot be 0")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool asset address cannot be 0"));
        require(daiPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ipToken address cannot be 0"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammStorage address cannot be 0"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammTreasury address cannot be 0"));
        require(
            daiPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI pool assetManagement address cannot be 0")
        );

        require(iporOracle != address(0), string.concat(IporErrors.WRONG_ADDRESS, " iporOracle address cannot be 0"));

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtIpToken = usdtPoolCfg.ipToken;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtAssetManagement = usdtPoolCfg.assetManagement;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcIpToken = usdcPoolCfg.ipToken;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcAssetManagement = usdcPoolCfg.assetManagement;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.decimals;
        _daiIpToken = daiPoolCfg.ipToken;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiAssetManagement = daiPoolCfg.assetManagement;

        _iporOracle = iporOracle;
    }

    function getAmmPoolsLensConfiguration(address asset) external view override returns (AmmPoolsLensPoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        return _getPoolCoreModel(asset).getExchangeRate();
    }

    function getAmmBalance(address asset) external view override returns (IporTypes.AmmBalancesMemory memory balance) {
        return _getPoolCoreModel(asset).getAccruedBalance();
    }

    function getLiquidityPoolAccountContribution(address asset, address account) external view returns (uint256) {
        AmmPoolsLensPoolConfiguration memory poolCfg = _getPoolConfiguration(asset);
        return IAmmStorage(poolCfg.ammStorage).getLiquidityPoolAccountContribution(account);
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
        model.iporOracle = _iporOracle;

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
