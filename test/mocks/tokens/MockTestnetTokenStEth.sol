// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockTestnetToken.sol";

contract MockTestnetTokenStEth is MockTestnetToken {
    /// @dev Collected ETH in stETH by user.
    mapping(address => uint256) public balanceOfEth;

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

    /// @notice Withdraws ETH from stETH contract in relation 1:1.
    /// @dev Notice! Not every stETH can be exchange to ETH, only stETH that was submitted or received as a ETH to stETH contract.
    /// @dev stETH minted by Faucet contract can't be redeemed.
    function redeemEth(uint256 ethAmount) public payable {
        require(balanceOfEth[msg.sender] >= ethAmount, "NOT_ENOUGH_BALANCE");
        balanceOfEth[msg.sender] -= ethAmount;
        payable(msg.sender).transfer(ethAmount);
    }

    function _submit() internal returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");
        balanceOfStEth[msg.sender] += msg.value;
        _mint(msg.sender, msg.value);
        return msg.value;
    }
}
