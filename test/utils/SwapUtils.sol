// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../contracts/itf/ItfMilton.sol";

contract SwapUtils is Test {
	
	function iterateOpenSwapsPayFixed(
		address user,
		ItfMilton milton, 
		uint256 numberIterations,
		uint256 totalAmount,
		uint256 leverage
	) public {
		for (uint256 i = 0; i < numberIterations; i++) {
			if (i % 2 == 0) {
				uint256 acceptableFixedInterestRate = 9 * 10**17; // 9 * N0__1_18DEC
				vm.prank(user);
				milton.itfOpenSwapPayFixed(
					block.timestamp, // openTimestamp
					totalAmount, // totalAmount
					acceptableFixedInterestRate, // acceptableFixedInterestRate 
					leverage // leverage LEVERAGE_18DEC
				);
			} else {
				uint256 acceptableFixedInterestRate = 1 * 10**17; // N0__1_18DEC
				vm.prank(user);
				milton.itfOpenSwapPayFixed(
					block.timestamp, // openTimestamp
					totalAmount, // totalAmount
					acceptableFixedInterestRate, // acceptableFixedInterestRate
					leverage // leverage LEVERAGE_18DEC
				);
			}
		}
	}
}
