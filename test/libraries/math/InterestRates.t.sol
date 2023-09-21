// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../../contracts/libraries/math/InterestRates.sol";

contract InterestRatesTest is Test {
    using InterestRates for uint256;

    uint256 internal constant D18 = 1e18;

    function testShouldAddContinuousCompoundInterest() public {
        uint256 oneHundred = 100 * D18;

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(3e16 * 365 days),
            103045453395351685664
        );
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(3e16 * 120 days + 3e16 * 245 days),
            103045453395351685664
        );
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                3e16 * 120 days + 3e16 * 120 days + 3e16 * 125 days
            ),
            103045453395351685664
        );

        uint256 ipmDaily = 0;
        for (uint256 i; i < 365; ++i) {
            ipmDaily += 3e16 * 1 days;
        }
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(ipmDaily),
            103045453395351685664
        );

        uint256 ipmHourly = 0;
        for (uint256 i; i < 365 * 24; ++i) {
            ipmHourly += 3e16 * 1 hours;
        }
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(ipmHourly),
            103045453395351685664
        );

        uint256 ipmWeekly = 0;
        for (uint256 i; i < 52; ++i) {
            ipmWeekly += 3e16 * 7 days;
        }
        ipmWeekly += 3e16 * 1 days;
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(ipmWeekly),
            103045453395351685664
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(3e16 * 730 days),
            106183654654535962328
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(3e16 * 3650 days),
            134985880757600310533
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                1e16 * 120 days + 3e16 * 120 days + 2e16 * 120 days
            ),
            101992187109547346999
        );

        assertEq(oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(0), oneHundred);
    }

    function testShouldCalculateInterest() public {
        uint256 oneHundred = 100 * D18;

        assertEq(
            oneHundred.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(8e16 * 25 days),
            549449170934577930
        );

        assertEq(
            oneHundred.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(8e16 * 365 days),
            8328706767495855551
        );

        uint256 amount = D18;
        uint256 interest = 0;
        for (uint256 i; i < 365; ++i) {
            interest += (amount + interest).calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                8e16 * 1 days
            );
        }
        assertEq(amount + interest, 1083287067674959202);
    }
}
