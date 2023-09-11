// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/security/IporOwnable.sol";

contract MockTestnetTokenStEth is ERC20, IporOwnable {
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

    /// @dev Attention! This is only mock used in stETH pool, behavior is not the same as in real contract stETH.
    /// @dev For testing real accrued interest from stETH it is recommended to use forked Mainnet and real stETH contract.
    function submit(address _referral) external payable returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");
        _mint(msg.sender, msg.value);
        return msg.value;
    }
}
