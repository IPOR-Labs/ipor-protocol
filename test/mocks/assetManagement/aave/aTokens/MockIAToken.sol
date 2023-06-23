// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/vault/interfaces/aave/AToken.sol";

interface MockIAToken {
    function burn(address user, uint256 amount) external;

    function mint(address account, uint256 amount) external;
}
