// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/security/IporOwnable.sol";

contract MockTestnetToken is ERC20, IporOwnable {
    uint8 private _customDecimals;
    mapping (address => bool) public isBlackListed;


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

    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function addToBlackList(address account) external virtual onlyOwner {
        isBlackListed[account] = true;
    }

    function removeFromBlackList(address account) external virtual onlyOwner {
        isBlackListed[account] = false;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (isBlackListed[msg.sender]) {
            revert("Blacklisted address");
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (isBlackListed[from]) {
            revert("Blacklisted address");
        }
        return super.transferFrom(from, to, amount);
    }

    

    /// @dev used only for Compound Share Token
    function accrueInterest() public returns (uint256) {}
}
