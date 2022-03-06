pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/aave/AToken.sol";

interface MockIAToken {
    function burn(address user, uint256 amount) external;

    function mint(address account, uint256 amount) external;
}
