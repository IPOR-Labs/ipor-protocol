// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./ISpread28Days.sol";
import "./Spread28DaysConfigLibs.sol";
import "./BaseSpread28DaysLibs.sol";

contract Spread28Days is ISpread28Days {
    using SafeCast for uint256;
    using SafeCast for int256;

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

    function calculateQuotePayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsPayFixed(
            asset,
            accruedIpor,
            accruedBalance
        );

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() + spreadPremiums;

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    function calculateQuoteReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        return 1;
    }

    function _calculateSpreadPremiumsPayFixed(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
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
