// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockTestnetShareTokenAaveUsdc is MockTestnetToken {
    constructor(uint256 initialSupply)
        MockTestnetToken("Mocked Share aUSDC", "aUSDC", initialSupply, 6)
    {}
}
