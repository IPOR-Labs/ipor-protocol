// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@ipor-protocol/contracts/security/IporOwnable.sol";

contract MockTestnetToken is ERC20, IporOwnable {
    uint8 private _customDecimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimalsInput
    ) ERC20(name, symbol) {
        _customDecimals = decimalsInput;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @dev used only for Compound Share Token
    function accrueInterest() public returns (uint256) {}
}
