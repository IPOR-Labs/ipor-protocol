// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Spread28DaysConfigLibs.sol";
import "../../interfaces/types/IporTypes.sol";
import "./ISpreadLens.sol";
import "./BaseSpread28DaysLibs.sol";


contract SpreadLens is ISpreadLens{

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _DAI;
        assets[1] = _USDC;
        assets[2] = _USDT;
        return assets;
    }

    function getBaseSpreadConfig(address asset) external view returns (Spread28DaysConfigLibs.BaseSpreadConfig memory) {
        if (asset == _DAI) {
            return Spread28DaysConfigLibs._getBaseSpreadDaiConfig();
        }
        if (asset == _USDC) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdcConfig();
        }
        if (asset == _USDT) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdtConfig();
        }
        revert("SpreadLens: asset not supported"); //TODO: Do we want costume error code ?
    }

    function calculateBaseSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsPayFixed(
        asset,
        accruedIpor,
        accruedBalance
        );
    }

    function calculateSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        // TODO: implement with imbalance part
        spreadValue = _calculateSpreadPremiumsPayFixed(
            asset,
            accruedIpor,
            accruedBalance
        );
    }

    function calculateBaseSpreadReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsReceiveFixed(asset, accruedIpor, accruedBalance);
    }

    function calculateSpreadReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        // TODO: implement with imbalance part
        spreadValue = _calculateSpreadPremiumsReceiveFixed(asset, accruedIpor, accruedBalance);
    }

    function _calculateSpreadPremiumsReceiveFixed(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) internal view virtual returns (int256 baseSpread) {
        return
        BaseSpread28DaysLibs._calculateSpreadPremiumsReceiveFixed(
            accruedIpor,
            accruedBalance,
            _getBaseSpreadConfig(asset)
        );
    }

    function _calculateSpreadPremiumsPayFixed(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) internal view virtual returns (int256 baseSpread) {
        return
        BaseSpread28DaysLibs._calculateSpreadPremiumsPayFixed(
            accruedIpor,
            accruedBalance,
            _getBaseSpreadConfig(asset)
        );
    }

    function _getBaseSpreadConfig(address asset)
    internal
    view
    returns (Spread28DaysConfigLibs.BaseSpreadConfig memory)
    {
        if (asset == _DAI) {
            return Spread28DaysConfigLibs._getBaseSpreadDaiConfig();
        }
        if (asset == _USDC) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdcConfig();
        }
        if (asset == _USDT) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdtConfig();
        }
        revert("Spread: asset not supported");
        //TODO: Do we want costume error code ?
    }

}

