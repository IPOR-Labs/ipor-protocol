// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporVault {
    function totalBalance(address who) external view returns (uint256);

    function deposit(uint256 assetValue) external returns (uint256 balance);

    function withdraw(uint256 assetValue)
        external
        returns (uint256 withdrawnValue, uint256 balance);
}
