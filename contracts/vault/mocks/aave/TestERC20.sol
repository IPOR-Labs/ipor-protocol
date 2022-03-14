// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    constructor(uint256 amountToMint) ERC20("TestERC20", "test") {
        mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 amount) public {
        uint256 balanceNext = _balance[to] + amount;
        require(balanceNext >= amount, "overflow balance");
        _balance[to] = balanceNext;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 balanceBefore = _balance[msg.sender];
        require(balanceBefore >= amount, "insufficient balance");
        _balance[msg.sender] = balanceBefore - amount;

        uint256 balanceRecipient = _balance[recipient];
        require(balanceRecipient + amount >= balanceRecipient, "recipient balance overflow");
        _balance[recipient] = balanceRecipient + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowanceBefore = _allowance[sender][msg.sender];
        require(allowanceBefore >= amount, "allowance insufficient");

        _allowance[sender][msg.sender] = allowanceBefore - amount;

        uint256 balanceRecipient = _balance[recipient];
        require(balanceRecipient + amount >= balanceRecipient, "overflow balance recipient");
        _balance[recipient] = balanceRecipient + amount;
        uint256 balanceSender = _balance[sender];
        require(balanceSender >= amount, "underflow balance sender");
        _balance[sender] = balanceSender - amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
