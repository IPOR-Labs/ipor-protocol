// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

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

    constructor(
        PoolConfiguration memory usdtPoolCfg,
        PoolConfiguration memory usdcPoolCfg,
        PoolConfiguration memory daiPoolCfg
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " asset USDT address cannot be 0"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammStorage USDT address cannot be 0"));
        require(usdtPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammTreasury USDT address cannot be 0"));
        require(
            usdtPoolCfg.ammPoolsTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasury USDT address cannot be 0")
        );
        require(
            usdtPoolCfg.ammPoolsTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasuryManager USDT address cannot be 0")
        );
        require(
            usdtPoolCfg.ammCharlieTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasury USDT address cannot be 0")
        );
        require(
            usdtPoolCfg.ammCharlieTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasuryManager USDT address cannot be 0")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " asset USDC address cannot be 0"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammStorage USDC address cannot be 0"));
        require(usdcPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammTreasury USDC address cannot be 0"));
        require(
            usdcPoolCfg.ammPoolsTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasury USDC address cannot be 0")
        );
        require(
            usdcPoolCfg.ammPoolsTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasuryManager USDC address cannot be 0")
        );
        require(
            usdcPoolCfg.ammCharlieTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasury USDC address cannot be 0")
        );
        require(
            usdcPoolCfg.ammCharlieTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasuryManager USDC address cannot be 0")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " asset DAI address cannot be 0"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammStorage DAI address cannot be 0"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammTreasury DAI address cannot be 0"));
        require(
            daiPoolCfg.ammPoolsTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasury DAI address cannot be 0")
        );
        require(
            daiPoolCfg.ammPoolsTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammPoolsTreasuryManager DAI address cannot be 0")
        );
        require(
            daiPoolCfg.ammCharlieTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasury DAI address cannot be 0")
        );
        require(
            daiPoolCfg.ammCharlieTreasuryManager != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ammCharlieTreasuryManager DAI address cannot be 0")
        );

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.assetDecimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtAmmPoolsTreasury = usdtPoolCfg.ammPoolsTreasury;
        _usdtAmmPoolsTreasuryManager = usdtPoolCfg.ammPoolsTreasuryManager;
        _usdtAmmCharlieTreasury = usdtPoolCfg.ammCharlieTreasury;
        _usdtAmmCharlieTreasuryManager = usdtPoolCfg.ammCharlieTreasuryManager;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.assetDecimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcAmmPoolsTreasury = usdcPoolCfg.ammPoolsTreasury;
        _usdcAmmPoolsTreasuryManager = usdcPoolCfg.ammPoolsTreasuryManager;
        _usdcAmmCharlieTreasury = usdcPoolCfg.ammCharlieTreasury;
        _usdcAmmCharlieTreasuryManager = usdcPoolCfg.ammCharlieTreasuryManager;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.assetDecimals;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiAmmPoolsTreasury = daiPoolCfg.ammPoolsTreasury;
        _daiAmmPoolsTreasuryManager = daiPoolCfg.ammPoolsTreasuryManager;
        _daiAmmCharlieTreasury = daiPoolCfg.ammCharlieTreasury;
        _daiAmmCharlieTreasuryManager = daiPoolCfg.ammCharlieTreasuryManager;
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
        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        require(msg.sender == poolCfg.ammPoolsTreasuryManager, AmmPoolsErrors.CALLER_NOT_TREASURY_MANAGER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, poolCfg.assetDecimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.assetDecimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToTreasury(wadAssetAmount);

        IERC20Upgradeable(asset).safeTransferFrom(
            poolCfg.ammTreasury,
            poolCfg.ammPoolsTreasury,
            assetAmountAssetDecimals
        );
    }

    function transferToCharlieTreasury(address asset, uint256 assetAmount) external override {
        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        require(msg.sender == poolCfg.ammCharlieTreasuryManager, AmmPoolsErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, poolCfg.assetDecimals);
        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, poolCfg.assetDecimals);

        IAmmStorage(poolCfg.ammStorage).updateStorageWhenTransferToCharlieTreasury(wadAssetAmount);

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

    function addAppointedToRebalanceInAmm(address asset, address account) external override {
        AmmConfigurationManager.addAppointedToRebalanceInAmm(asset, account);
    }

    function removeAppointedToRebalanceInAmm(address asset, address account) external override {
        AmmConfigurationManager.removeAppointedToRebalanceInAmm(asset, account);
    }

    function isAppointedToRebalanceInAmm(address asset, address account) external view override returns (bool) {
        return AmmConfigurationManager.isAppointedToRebalanceInAmm(asset, account);
    }

    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newMaxLpAccountContribution,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external override {
        AmmConfigurationManager.setAmmPoolsParams(
            asset,
            newMaxLiquidityPoolBalance,
            newMaxLpAccountContribution,
            newAutoRebalanceThresholdInThousands,
            newAmmTreasuryAndAssetManagementRatio
        );
    }

    function getAmmPoolsParams(address asset) external view override returns (StorageLib.AmmPoolsParamsValue memory) {
        return AmmConfigurationManager.getAmmPoolsParams(asset);
    }

    function _getPoolConfiguration(address asset) internal view returns (PoolConfiguration memory) {
        if (asset == _usdt) {
            return
                PoolConfiguration({
                    asset: _usdt,
                    assetDecimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    ammPoolsTreasury: _usdtAmmPoolsTreasury,
                    ammPoolsTreasuryManager: _usdtAmmPoolsTreasuryManager,
                    ammCharlieTreasury: _usdtAmmCharlieTreasury,
                    ammCharlieTreasuryManager: _usdtAmmCharlieTreasuryManager
                });
        } else if (asset == _usdc) {
            return
                PoolConfiguration({
                    asset: _usdc,
                    assetDecimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    ammPoolsTreasury: _usdcAmmPoolsTreasury,
                    ammPoolsTreasuryManager: _usdcAmmPoolsTreasuryManager,
                    ammCharlieTreasury: _usdcAmmCharlieTreasury,
                    ammCharlieTreasuryManager: _usdcAmmCharlieTreasuryManager
                });
        } else if (asset == _dai) {
            return
                PoolConfiguration({
                    asset: _dai,
                    assetDecimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    ammPoolsTreasury: _daiAmmPoolsTreasury,
                    ammPoolsTreasuryManager: _daiAmmPoolsTreasuryManager,
                    ammCharlieTreasury: _daiAmmCharlieTreasury,
                    ammCharlieTreasuryManager: _daiAmmCharlieTreasuryManager
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
