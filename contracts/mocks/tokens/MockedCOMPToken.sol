// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TestnetMockedToken.sol";

//solhint-disable no-empty-blocks
contract MockedCOMPToken is TestnetMockedToken {
    constructor(uint256 initialSupply, uint8 decimals)
        TestnetMockedToken("Mocked COMP", "COMP", initialSupply, decimals)
    {}
}
