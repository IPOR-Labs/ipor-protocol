// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

//Opcja A
interface IIporVault {
    function totalBalance(address who) external view returns (uint256);

    function deposit(uint256 assetValue) external returns (uint256 balance);

    function withdraw(uint256 assetValue) external returns (uint256 balance);
}

// interface IIporVault {

//     function totalBalance(address who) external view returns (uint256);

//     function deposit(uint256 assetValue) external returns (uint256 balance);

//     function withdraw(uint256 assetValue) external returns (uint256 balance);

// 	//0. vaultBalance = 1000;
// 	//1. deposit - 100
// 	//2. ???? balance - (vaultBalance + deposit) = interest, lpBalance = lpBalance + interest;
// 	//3. vaultBalance = balance
// 	//4. openPosition ???? lpBalance + interestPrim, interestPrim = balance - vaultBalance
// }
