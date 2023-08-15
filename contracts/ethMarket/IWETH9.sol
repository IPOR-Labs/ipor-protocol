// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETH9 is IERC20{
    function deposit() external payable;
    function withdraw(uint wad) external;
}
