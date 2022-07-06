// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../vault/interfaces/aave/AToken.sol";

interface MockIAToken {
    function burn(address user, uint256 amount) external;

    function mint(address account, uint256 amount) external;
}
