// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./MockTestnetToken.sol";

//solhint-disable no-empty-blocks
contract MockedCOMPToken is MockTestnetToken {
    constructor(uint256 initialSupply, uint8 decimals)
        MockTestnetToken("Mocked COMP", "COMP", initialSupply, decimals)
    {}
}
