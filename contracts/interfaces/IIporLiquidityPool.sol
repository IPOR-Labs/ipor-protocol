// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IIporLiquidityPool {

    function calculateExchangeRate(address asset) external returns (uint256);
}