// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporVault { 

	function totalBalance(address who) external view returns (uint256);
	function deposit(uint256 assetValue) external returns(uint256 currentBalance, uint256 currentInterest);
	function withdraw(uint256 ivTokenValue) external returns(uint256 withdrawAssetValue, uint256 currentInterest);
	function currentInterest(address who) external returns(uint256);
}