// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/IERC20Minimal.sol";
import "hardhat/console.sol";

contract TestERC20 is IERC20Minimal {
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(uint256 amountToMint) {
        mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 amount) public {
        uint256 balanceNext = balance[to] + amount;
        require(balanceNext >= amount, "overflow balance");
        balance[to] = balanceNext;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        uint256 balanceBefore = balance[msg.sender];
        require(balanceBefore >= amount, "insufficient balance");
        balance[msg.sender] = balanceBefore - amount;

        uint256 balanceRecipient = balance[recipient];
        require(
            balanceRecipient + amount >= balanceRecipient,
            "recipient balance overflow"
        );
        balance[recipient] = balanceRecipient + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 allowanceBefore = allowance[sender][msg.sender];
        require(allowanceBefore >= amount, "allowance insufficient");

        allowance[sender][msg.sender] = allowanceBefore - amount;

        uint256 balanceRecipient = balance[recipient];
        require(
            balanceRecipient + amount >= balanceRecipient,
            "overflow balance recipient"
        );
        balance[recipient] = balanceRecipient + amount;
        uint256 balanceSender = balance[sender];
        require(balanceSender >= amount, "underflow balance sender");
        balance[sender] = balanceSender - amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balance[account];
    }

    function decimals() external view returns (uint256) {
        return 18;
    }
}
