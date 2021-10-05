// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockedToken.sol";

contract UsdtMockedToken is MockedToken {

    constructor(
        uint256 initialSupply,
        uint8 _decimals
    ) MockedToken("Mocked USDT", "USDT", initialSupply, _decimals) {}
}
