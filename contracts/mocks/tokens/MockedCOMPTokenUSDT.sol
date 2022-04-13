// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockedToken.sol";

//solhint-disable no-empty-blocks
contract MockedCOMPTokenUSDT is MockedToken {
    constructor(uint256 initialSupply, uint8 decimals)
        MockedToken("Mocked USDT", "USDT", initialSupply, decimals)
    {}
}
