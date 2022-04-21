// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockedToken.sol";

//TODO: can be removed
//solhint-disable no-empty-blocks
contract MockedCOMPTokenUSDC is MockedToken {
    constructor(uint256 initialSupply, uint8 decimals)
        MockedToken("Mocked USDC", "USDC", initialSupply, decimals)
    {}
}
