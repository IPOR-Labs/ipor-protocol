pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockIAToken.sol";

contract MockAUsdc is ERC20, MockIAToken {
    constructor() ERC20("aUsdc", "aUsdc") {}

    function burn(address user, uint256 amount) external {
        _burn(user, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
