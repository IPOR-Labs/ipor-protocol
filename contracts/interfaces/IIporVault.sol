// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporVault {
	
    function totalBalance() external view returns (uint256);

    function deposit(uint256 assetValue) external returns (uint256 interest);

    function withdraw(uint256 assetValue) external returns (uint256 interest);

    function getCurrentInterest() external view returns (uint256);
}
