// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/libraries/math/InterestRates.sol";

contract InterestRatesTest is Test {
    using InterestRates for uint256;

    uint256 internal constant D18 = 1e18;

    function testShouldAddContinuousCompoundInterest() public {
        uint256 oneHundred = 100 * D18;

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(3e16 * 365 days, 365 days)
            ),
            103045453395351685664
        );
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(3e16 * 120 days + 3e16 * 245 days, 365 days)
            ),
            103045453395351685664
        );
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(3e16 * 120 days + 3e16 * 120 days + 3e16 * 125 days, 365 days)
            ),
            103045453395351685664
        );

        uint256 ipmDaily = 0;
        for (uint256 i; i < 365; ++i) {
            ipmDaily += 3e16 * 1 days;
        }
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(ipmDaily, 365 days)
            ),
            103045453395351685664
        );

        uint256 ipmHourly = 0;
        for (uint256 i; i < 365 * 24; ++i) {
            ipmHourly += 3e16 * 1 hours;
        }
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(ipmHourly, 365 days)
            ),
            103045453395351685664
        );

        uint256 ipmWeekly = 0;
        for (uint256 i; i < 52; ++i) {
            ipmWeekly += 3e16 * 7 days;
        }
        ipmWeekly += 3e16 * 1 days;
        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(ipmWeekly, 365 days)
            ),
            103045453395351685664
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(3e16 * 730 days, 365 days)
            ),
            106183654654535962328
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(3e16 * 3650 days, 365 days)
            ),
            134985880757600310533
        );

        assertEq(
            oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(1e16 * 120 days + 3e16 * 120 days + 2e16 * 120 days, 365 days)
            ),
            101992187109547346999
        );

        assertEq(oneHundred.addContinuousCompoundInterestUsingRatePeriodMultiplication(0), oneHundred);
    }

    function testShouldCalculateInterest() public {
        uint256 oneHundred = 100 * D18;

        assertEq(
            oneHundred.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                IporMath.division(8e16 * 25 days, 365 days)
            ),
            549449170934577930
        );
    }
}
