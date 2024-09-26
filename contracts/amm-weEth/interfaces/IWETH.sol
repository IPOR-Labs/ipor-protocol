// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of the Wrapped ETH contract.
interface IWETH is IERC20 {
    function withdraw(uint wad) external;

    function deposit() external payable;
}
