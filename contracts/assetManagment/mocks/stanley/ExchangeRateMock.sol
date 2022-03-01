// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../stanley/ExchangeRate.sol";

contract ExchangeRateMock is ExchangeRate {
    function calculateExchangeRate(
        uint256 _totalAssetsDollar,
        uint256 _totalTokensIssued
    ) public pure returns (uint256) {
        return _calculateExchangeRate(_totalAssetsDollar, _totalTokensIssued);
    }
}
