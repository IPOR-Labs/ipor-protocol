// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/libraries/math/InterestRates.sol";

contract InterestRatesTest is Test {
    using InterestRates for uint256;

    uint256 internal constant D18 = 1e18;

    function testShouldAddContinuousCompoundInterest() public {
//        uint256 oneHundred = 100 * D18;
//
//        assertEq(oneHundred.addContinuousCompoundInterest(3 * 1e16, 365 days), 103045453395351685664);
//        assertEq(
//            oneHundred.addContinuousCompoundInterest(3 * 1e16, 120 days).addContinuousCompoundInterest(
//                3 * 1e16,
//                245 days
//            ),
//            103045453395351685664
//        );
//        assertEq(
//            oneHundred
//                .addContinuousCompoundInterest(3 * 1e16, 120 days)
//                .addContinuousCompoundInterest(3 * 1e16, 125 days)
//                .addContinuousCompoundInterest(3 * 1e16, 120 days),
//            103045453395351685664
//        );
//
//        uint256 value = oneHundred;
//        for (uint256 i;i<=365;++i) {
//            value = value.addContinuousCompoundInterest(3 * 1e16, 1 days);
//        }
//        assertEq(value, 103045453395351685664);
//
//        uint256 valueHourly = oneHundred;
//        for (uint256 i;i<=365*24;++i) {
//            valueHourly = valueHourly.addContinuousCompoundInterest(3 * 1e16, 1 hours);
//        }
//        assertEq(valueHourly, 103045453395351685664);
//
//        uint256 valueWeekly = oneHundred;
//        for (uint256 i;i<=52;++i) {
//            valueWeekly = valueWeekly.addContinuousCompoundInterest(3 * 1e16, 7 days);
//        }
//        valueWeekly=valueWeekly.addContinuousCompoundInterest(3 * 1e16, 1 days);
//        assertEq(valueWeekly, 103045453395351685664);
//
//        assertEq(oneHundred.addContinuousCompoundInterest(0, 0), oneHundred);
    }
}
