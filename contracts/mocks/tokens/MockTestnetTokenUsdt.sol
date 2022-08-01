// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockTestnetTokenUsdt is MockTestnetToken {
    constructor(uint256 initialSupply) MockTestnetToken("Mocked USDT", "USDT", initialSupply, 6) {}
}
