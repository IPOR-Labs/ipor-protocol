// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockedCOMPToken is MockTestnetToken {
    constructor(uint256 initialSupply, uint8 decimals)
        MockTestnetToken("Mocked COMP", "COMP", initialSupply, decimals)
    {}
}
