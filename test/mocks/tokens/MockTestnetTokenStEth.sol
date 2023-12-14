// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

contract MockTestnetTokenStEth is MockTestnetToken {
    mapping(address => uint256) public balanceOfStEth;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimalsInput
    ) MockTestnetToken(name, symbol, initialSupply, decimalsInput) {}

    receive() external payable {
        _submit();
    }

    /// @dev Attention! This is only mock used in stETH pool, behavior is not the same as in real contract stETH.
    /// @dev For testing real accrued interest from stETH it is recommended to use forked Mainnet and real stETH contract.
    function submit(address) external payable returns (uint256) {
        return _submit();
    }

    function withdrawEth(uint256 ethAmount) public payable {
        require(balanceOfStEth[msg.sender] >= ethAmount);
        balanceOfStEth[msg.sender] -= ethAmount;
        payable(msg.sender).transfer(ethAmount);
    }

    function _submit() internal returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");
        balanceOfStEth[msg.sender] += msg.value;
        _mint(msg.sender, msg.value);
        return msg.value;
    }
}
