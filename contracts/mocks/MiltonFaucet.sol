// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MiltonFaucet {
    using SafeERC20 for IERC20;

    fallback() external payable {}

    receive() external payable {}

    function transferEth(address payable recipient, uint256 value) external payable {
        recipient.transfer(value);
    }

    function transfer(address asset, uint256 value) external {
        ERC20 token = ERC20(asset);
        uint256 decimals = token.decimals();
        uint256 maxValue = 1000000 * decimals * 10**token.decimals();
        require(value <= maxValue, "Too much value for transfer");
        IERC20(asset).safeTransfer(msg.sender, value);
    }

    function balanceOfEth() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address asset) external view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }
}
