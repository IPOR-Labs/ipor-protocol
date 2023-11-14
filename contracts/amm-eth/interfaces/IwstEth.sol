// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of the Wrapped ETH contract.
interface IwstEth is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 wstEthAmount)  external returns (uint256);
}
