// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockTestnetShareTokenCompoundUsdc is MockTestnetToken {
    constructor(uint256 initialSupply)
        MockTestnetToken("Mocked Share cUSDC", "cUSDC", initialSupply, 6)
    {}
}
