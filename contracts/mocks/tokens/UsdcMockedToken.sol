// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockedToken.sol";

contract UsdcMockedToken is MockedToken {

    constructor(
        uint256 initialSupply,
        uint8 decimals
    ) MockedToken("Mocked USDC", "USDC", initialSupply, decimals) {}
}
