// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {AmMath} from "../libraries/AmMath.sol";

// TODO: take into account decimals specific for asset
abstract contract ExchangeRate {
    function _calculateExchangeRate(uint256 _assetAmount, uint256 _tokenAmount)
        internal
        pure
        returns (uint256 result)
    {
        if (_tokenAmount == 0 || _assetAmount == 0) {
            return 1e18;
        }
        return AmMath.division(_assetAmount * 1e18, _tokenAmount);
    }

    function _calculateExchangeRateRoundDown(
        uint256 _assetAmount,
        uint256 _tokenAmount
    ) internal pure returns (uint256) {
        if (_tokenAmount == 0 || _assetAmount == 0) {
            return 1e18;
        }
        return AmMath.divisionRoundDown(_assetAmount * 1e18, _tokenAmount);
    }
}
