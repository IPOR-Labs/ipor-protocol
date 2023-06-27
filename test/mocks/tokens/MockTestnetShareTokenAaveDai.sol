// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockTestnetShareTokenAaveDai is MockTestnetToken {
    constructor(uint256 initialSupply)
        MockTestnetToken("Mocked Share aDAI", "aDAI", initialSupply, 18)
    {}
}
