// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract AAVEMockedToken is MockTestnetToken {
    constructor(uint256 initialSupply, uint8 decimals)
        MockTestnetToken("Mocked AAVE", "AAVE", initialSupply, decimals)
    {}
}
