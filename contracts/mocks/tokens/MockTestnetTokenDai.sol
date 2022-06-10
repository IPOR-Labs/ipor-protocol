// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockTestnetTokenDai is MockTestnetToken {
    constructor(uint256 initialSupply) MockTestnetToken("Mocked DAI", "DAI", initialSupply, 18) {}
}
