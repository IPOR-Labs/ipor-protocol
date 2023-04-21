// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Spread28DaysConfigLibs.sol";


contract SpreadLens {

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

}

