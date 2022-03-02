// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../stanley/ExchangeRate.sol";

// TODO: We have to decide Mock is a prefix or postfix and use this approach consistently everywhere
contract ExchangeRateMock is ExchangeRate {
    // TODO: REmove dollar
    function calculateExchangeRate(
        uint256 totalAssetsDollar,
        uint256 totalTokensIssued
    ) external pure returns (uint256) {
        return _calculateExchangeRate(totalAssetsDollar, totalTokensIssued);
    }
}
