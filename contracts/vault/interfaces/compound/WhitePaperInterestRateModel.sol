// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface WhitePaperInterestRateModel {
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}
