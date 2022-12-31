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
	
	function iterateOpenSwapsReceiveFixed(
		address user,
		ItfMilton milton, 
		uint256 numberIterations,
		uint256 totalAmount,
		uint256 leverage
	) public {
		for (uint256 i = 0; i < numberIterations; i++) {
			if (i % 2 == 0) {
				uint256 acceptableFixedInterestRate = 1 * 10**16;
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
				milton.itfOpenSwapReceiveFixed(
					block.timestamp, // openTimestamp
					totalAmount, // totalAmount
					acceptableFixedInterestRate, // acceptableFixedInterestRate
					leverage // leverage LEVERAGE_18DEC
				);
			}
		}
	}

	function calculateSoap(
		address from,
		uint256 calculateTimestamp,
		ItfMilton milton
	) public returns (int256, int256, int256)
	{
		vm.prank(from);
		(int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = milton.itfCalculateSoap(calculateTimestamp);
		return (soapPayFixed, soapReceiveFixed, soap);
	}

	function openSwapPayFixed(
		address from,
		uint256 openTimestamp,
		uint256 totalAmount,
		uint256 acceptableFixedInterestRate,
		uint256 leverage,
		ItfMilton milton
	) public {
		vm.prank(from);
		milton.itfOpenSwapPayFixed(
			openTimestamp, // openTimestamp
			totalAmount, // totalAmount
			acceptableFixedInterestRate, // acceptableFixedInterestRate
			leverage // leverage LEVERAGE_18DEC
		);
	}

	function openSwapReceiveFixed(
		address from,
		uint256 openTimestamp,
		uint256 totalAmount,
		uint256 acceptableFixedInterestRate,
		uint256 leverage,
		ItfMilton milton
	) public {
		vm.prank(from);
		milton.itfOpenSwapReceiveFixed(
			openTimestamp, // openTimestamp
			totalAmount, // totalAmount
			acceptableFixedInterestRate, // acceptableFixedInterestRate
			leverage // leverage LEVERAGE_18DEC
		);
	}

}
