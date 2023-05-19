// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../utils/TestConstants.sol";
import "contracts/itf/ItfMilton.sol";

contract SwapUtils is Test {
    function iterateOpenSwapsPayFixed(
        address user,
        ItfMilton milton,
        uint256 numberIterations,
        uint256 totalAmount,
        uint256 leverage
    ) public {
        for (uint256 i; i < numberIterations; ++i) {
            if (i % 2 == 0) {
                uint256 acceptableFixedInterestRate = 9 * TestConstants.D17;
                vm.prank(user);
                milton.openSwapPayFixed(
                    totalAmount, // totalAmount
                    acceptableFixedInterestRate, // acceptableFixedInterestRate
                    leverage // leverage
                );
            } else {
                uint256 acceptableFixedInterestRate = 1 * TestConstants.D17;
                vm.prank(user);
                milton.openSwapPayFixed(
                    totalAmount, // totalAmount
                    acceptableFixedInterestRate, // acceptableFixedInterestRate
                    leverage // leverage
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
        for (uint256 i; i < numberIterations; ++i) {
            uint256 acceptableFixedInterestRate = 1 * TestConstants.D16;
            vm.prank(user);
            milton.openSwapReceiveFixed(
                totalAmount, // totalAmount
                acceptableFixedInterestRate, // acceptableFixedInterestRate
                leverage // leverage
            );
        }
    }

    function calculateSoap(
        address from,
        uint256 calculateTimestamp,
        ItfMilton milton
    )
        public
        returns (
            int256,
            int256,
            int256
        )
    {
        vm.prank(from);
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = milton.itfCalculateSoap(calculateTimestamp);
        return (soapPayFixed, soapReceiveFixed, soap);
    }
}