// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockedToken is ERC20 {
    uint8 private _customDecimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _customDecimals = _decimals;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function setupInitialAmount(address user, uint256 initialAmount) external {
        _burn(user, balanceOf(user));
        _mint(user, initialAmount);
    }
}
