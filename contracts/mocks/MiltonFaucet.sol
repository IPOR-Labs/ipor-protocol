// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiltonFaucet {

    mapping(string => address) public tokens;

    constructor(
        address _usdt,
        address _usdc,
        address _dai,
        address _tusd) {

        tokens["USDT"] = _usdt;
        tokens["USDC"] = _usdc;
        tokens["DAI"] = _dai;
        tokens["TUSD"] = _tusd;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function transferEth(address payable recipient, uint256 value) external payable {
        recipient.transfer(value);
    }

    function transfer(string memory asset, uint256 value) external {
        //no more than 1 000 000 USD at once
        if (keccak256(abi.encodePacked(asset)) == keccak256(abi.encodePacked("USDT"))) {
            require(value <= 1000000000000, 'Too much USDT for transfer');
        }
        if (keccak256(abi.encodePacked(asset)) == keccak256(abi.encodePacked("USDC"))) {
            require(value <= 1000000000000, 'Too much USDC for transfer');
        }
        if (keccak256(abi.encodePacked(asset)) == keccak256(abi.encodePacked("TUSD"))) {
            require(value <= 1000000000000000000000000, 'Too much TUSD for transfer');
        }
        if (keccak256(abi.encodePacked(asset)) == keccak256(abi.encodePacked("DAI"))) {
            require(value <= 1000000000000000000000000, 'Too much DAI for transfer');
        }

        IERC20(tokens[asset]).transfer(msg.sender, value);
    }

    function balanceOf(string memory asset) external view returns (uint256) {
        if (keccak256(abi.encodePacked(asset)) == keccak256(abi.encodePacked("ETH"))) {
            return address(this).balance;
        } else {
            return IERC20(tokens[asset]).balanceOf(address(this));
        }

    }
}
