// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IporMath} from "../libraries/IporMath.sol";

// TODO: take into account decimals specific for asset
abstract contract ExchangeRate {
    function _calculateExchangeRate(uint256 assetAmount, uint256 tokenAmount)
        internal
        pure
        returns (uint256 result)
    {
        if (tokenAmount == 0 || assetAmount == 0) {
            return 1e18;
        }
        return IporMath.division(assetAmount * 1e18, tokenAmount);
    }

    function _calculateExchangeRateRoundDown(
        uint256 assetAmount,
        uint256 tokenAmount
    ) internal pure returns (uint256) {
        if (tokenAmount == 0 || assetAmount == 0) {
            return 1e18;
        }
        return IporMath.divisionWithoutRound(assetAmount * 1e18, tokenAmount);
    }
}
