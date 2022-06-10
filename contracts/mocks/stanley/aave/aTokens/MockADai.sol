// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockIAToken.sol";

contract MockADai is ERC20, MockIAToken {
    //solhint-disable no-empty-blocks
    constructor() ERC20("aDAI", "aDAI") {}

    function burn(address user, uint256 amount) external {
        _burn(user, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
