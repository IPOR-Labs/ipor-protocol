// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/libraries/math/IporMath.sol";
import "../TestConstants.sol";

contract IporMathTest is Test {
    uint256 public constant N1__0_18DEC = TestConstants.N1__0_18DEC;

    function testShouldDivide() public {
        assertDivision(0, 1, 0);
        assertDivision(1, 3, 0);
        assertDivision(100, 3, 33);
        assertDivision(100, 2, 50);

        assertDivision(10, 10, 1);
        assertDivision(11, 10, 1);
        assertDivision(12, 10, 1);
        assertDivision(13, 10, 1);
        assertDivision(14, 10, 1);
        assertDivision(15, 10, 2);
        assertDivision(16, 10, 2);
        assertDivision(17, 10, 2);
        assertDivision(18, 10, 2);
        assertDivision(19, 10, 2);
        assertDivision(20, 10, 2);

        vm.expectRevert();
        assertDivision(1, 0, 0);
    }

    function testShouldDivideInt() public {
        assertDivisionInt(0, 1, 0);
        assertDivisionInt(0, -1, 0);

        assertDivision(0, 1, 0);
        assertDivision(1, 3, 0);
        assertDivision(100, 3, 33);
        assertDivision(100, 2, 50);

        assertDivisionInt(10, 10, 1);
        assertDivisionInt(11, 10, 1);
        assertDivisionInt(12, 10, 1);
        assertDivisionInt(13, 10, 1);
        assertDivisionInt(14, 10, 1);
        assertDivisionInt(15, 10, 2);
        assertDivisionInt(16, 10, 2);
        assertDivisionInt(17, 10, 2);
        assertDivisionInt(18, 10, 2);
        assertDivisionInt(19, 10, 2);
        assertDivisionInt(20, 10, 2);

        vm.expectRevert();
        assertDivisionInt(1, 0, 0);
        vm.expectRevert();
        assertDivisionInt(-1, 0, 0);
        vm.expectRevert();
        assertDivisionInt(0, 0, 0);
    }

    function testShouldDivideWithoutRound() public {
        assertDivisionWithoutRound(0, 1, 0);
        assertDivisionWithoutRound(1, 3, 0);
        assertDivisionWithoutRound(100, 3, 33);
        assertDivisionWithoutRound(100, 2, 50);

        assertDivisionWithoutRound(10, 10, 1);
        assertDivisionWithoutRound(11, 10, 1);
        assertDivisionWithoutRound(12, 10, 1);
        assertDivisionWithoutRound(13, 10, 1);
        assertDivisionWithoutRound(14, 10, 1);
        assertDivisionWithoutRound(15, 10, 1);
        assertDivisionWithoutRound(16, 10, 1);
        assertDivisionWithoutRound(17, 10, 1);
        assertDivisionWithoutRound(18, 10, 1);
        assertDivisionWithoutRound(19, 10, 1);
        assertDivisionWithoutRound(20, 10, 2);

        vm.expectRevert();
        assertDivisionWithoutRound(1, 0, 0);
    }

    function testShouldConvertWadToAssetDecimalsWithoutRound() public {
        assetConvertWadToAssetDecimalsWithoutRound(N1__0_18DEC, 20, N1__0_18DEC * 100);

        assetConvertWadToAssetDecimalsWithoutRound(0, 18, 0);
        assetConvertWadToAssetDecimalsWithoutRound(0, 9, 0);
        assetConvertWadToAssetDecimalsWithoutRound(N1__0_18DEC, 36, N1__0_18DEC * 10**18);
        assetConvertWadToAssetDecimalsWithoutRound(N1__0_18DEC, 0, 1);
        assetConvertWadToAssetDecimalsWithoutRound(N1__0_18DEC, 18, N1__0_18DEC);
        assetConvertWadToAssetDecimalsWithoutRound(N1__0_18DEC, 16, N1__0_18DEC / 100);

        assetConvertWadToAssetDecimalsWithoutRound(10, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(11, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(12, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(13, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(14, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(15, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(16, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(17, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(18, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(19, 17, 1);
        assetConvertWadToAssetDecimalsWithoutRound(20, 17, 2);
    }

    function testShouldConvertWadToAssetDecimals() public {
        assetConvertWadToAssetDecimals(0, 18, 0);
        assetConvertWadToAssetDecimals(0, 9, 0);
        assetConvertWadToAssetDecimals(N1__0_18DEC, 20, N1__0_18DEC * 100);
        assetConvertWadToAssetDecimals(N1__0_18DEC, 36, N1__0_18DEC * 10**18);
        assetConvertWadToAssetDecimals(N1__0_18DEC, 0, 1);
        assetConvertWadToAssetDecimals(N1__0_18DEC, 18, N1__0_18DEC);
        assetConvertWadToAssetDecimals(N1__0_18DEC, 16, N1__0_18DEC / 100);

        assetConvertWadToAssetDecimals(10, 17, 1);
        assetConvertWadToAssetDecimals(11, 17, 1);
        assetConvertWadToAssetDecimals(12, 17, 1);
        assetConvertWadToAssetDecimals(13, 17, 1);
        assetConvertWadToAssetDecimals(14, 17, 1);
        assetConvertWadToAssetDecimals(15, 17, 2);
        assetConvertWadToAssetDecimals(16, 17, 2);
        assetConvertWadToAssetDecimals(17, 17, 2);
        assetConvertWadToAssetDecimals(18, 17, 2);
        assetConvertWadToAssetDecimals(19, 17, 2);
        assetConvertWadToAssetDecimals(20, 17, 2);
    }

    function testShouldConvertToWad() public {
        assetConvertToWad(N1__0_18DEC, 20, N1__0_18DEC / 100);

        assetConvertToWad(0, 18, 0);
        assetConvertToWad(N1__0_18DEC, 36, 1);
        assetConvertToWad(N1__0_18DEC, 0, N1__0_18DEC * 10**18);
        assetConvertToWad(N1__0_18DEC, 18, N1__0_18DEC);
        assetConvertToWad(N1__0_18DEC, 16, N1__0_18DEC * 100);

        assetConvertToWad(10, 19, 1);
        assetConvertToWad(11, 19, 1);
        assetConvertToWad(12, 19, 1);
        assetConvertToWad(13, 19, 1);
        assetConvertToWad(14, 19, 1);
        assetConvertToWad(15, 19, 2);
        assetConvertToWad(16, 19, 2);
        assetConvertToWad(17, 19, 2);
        assetConvertToWad(18, 19, 2);
        assetConvertToWad(19, 19, 2);
        assetConvertToWad(20, 19, 2);
    }

    function testShouldAbsoluteValue() public {
        assertEq(IporMath.absoluteValue(0), 0);
        assertEq(IporMath.absoluteValue(-10), 10);
        assertEq(IporMath.absoluteValue(10), 10);
    }

    function testShouldPercentOf() public {
        assertEq(IporMath.percentOf(0, 0), 0);

        assertEq(IporMath.percentOf(1000000000000000000, 1), 1);
        assertEq(IporMath.percentOf(1100000000000000000, 1), 1);
        assertEq(IporMath.percentOf(1200000000000000000, 1), 1);
        assertEq(IporMath.percentOf(1300000000000000000, 1), 1);
        assertEq(IporMath.percentOf(1400000000000000000, 1), 1);
        assertEq(IporMath.percentOf(1500000000000000000, 1), 2);
        assertEq(IporMath.percentOf(1600000000000000000, 1), 2);
        assertEq(IporMath.percentOf(1700000000000000000, 1), 2);
        assertEq(IporMath.percentOf(1800000000000000000, 1), 2);
        assertEq(IporMath.percentOf(1900000000000000000, 1), 2);
        assertEq(IporMath.percentOf(2000000000000000000, 1), 2);
    }

    function testShouldDivideIntNewAssert() public {
        assertEq(IporMath.divisionInt(0, 1), 0);
        assertEq(IporMath.divisionInt(0, -1), 0);

        assertEq(IporMath.divisionInt(0, 1), 0);
        assertEq(IporMath.divisionInt(1, 3), 0);
        assertEq(IporMath.divisionInt(100, 3), 33);
        assertEq(IporMath.divisionInt(100, 2), 50);

        assertEq(IporMath.divisionInt(1, -3), 0);
        assertEq(IporMath.divisionInt(-1, 3), 0);
        assertEq(IporMath.divisionInt(-100, 3), -33);
        assertEq(IporMath.divisionInt(100, -3), -33);
        assertEq(IporMath.divisionInt(-100, 2), -50);
        assertEq(IporMath.divisionInt(100, -2), -50);

        assertEq(IporMath.divisionInt(5, 10), 1);
        assertEq(IporMath.divisionInt(10, 10), 1);
        assertEq(IporMath.divisionInt(11, 10), 1);
        assertEq(IporMath.divisionInt(12, 10), 1);
        assertEq(IporMath.divisionInt(13, 10), 1);
        assertEq(IporMath.divisionInt(14, 10), 1);
        assertEq(IporMath.divisionInt(15, 10), 2);
        assertEq(IporMath.divisionInt(16, 10), 2);
        assertEq(IporMath.divisionInt(17, 10), 2);
        assertEq(IporMath.divisionInt(18, 10), 2);
        assertEq(IporMath.divisionInt(19, 10), 2);
        assertEq(IporMath.divisionInt(20, 10), 2);

        assertEq(IporMath.divisionInt(0, 10), 0);
        assertEq(IporMath.divisionInt(-1, 10), 0);
        assertEq(IporMath.divisionInt(-2, 10), 0);
        assertEq(IporMath.divisionInt(-3, 10), 0);
        assertEq(IporMath.divisionInt(-4, 10), 0);
        assertEq(IporMath.divisionInt(-5, 10), 0);
        assertEq(IporMath.divisionInt(-6, 10), -1);
        assertEq(IporMath.divisionInt(-7, 10), -1);
        assertEq(IporMath.divisionInt(-8, 10), -1);
        assertEq(IporMath.divisionInt(-9, 10), -1);
        assertEq(IporMath.divisionInt(-10, 10), -1);
        assertEq(IporMath.divisionInt(-11, 10), -1);
        assertEq(IporMath.divisionInt(-12, 10), -1);
        assertEq(IporMath.divisionInt(-13, 10), -1);
        assertEq(IporMath.divisionInt(-14, 10), -1);
        assertEq(IporMath.divisionInt(-15, 10), -1);
        assertEq(IporMath.divisionInt(-16, 10), -2);
        assertEq(IporMath.divisionInt(-17, 10), -2);
        assertEq(IporMath.divisionInt(-18, 10), -2);
        assertEq(IporMath.divisionInt(-19, 10), -2);
        assertEq(IporMath.divisionInt(-20, 10), -2);

        assertEq(IporMath.divisionInt(10, -10), -1);
        assertEq(IporMath.divisionInt(11, -10), -1);
        assertEq(IporMath.divisionInt(12, -10), -1);
        assertEq(IporMath.divisionInt(13, -10), -1);
        assertEq(IporMath.divisionInt(14, -10), -1);
        assertEq(IporMath.divisionInt(15, -10), -1);
        assertEq(IporMath.divisionInt(16, -10), -2);
        assertEq(IporMath.divisionInt(17, -10), -2);
        assertEq(IporMath.divisionInt(18, -10), -2);
        assertEq(IporMath.divisionInt(19, -10), -2);
        assertEq(IporMath.divisionInt(20, -10), -2);

        vm.expectRevert();
        IporMath.divisionInt(1, 0);
        vm.expectRevert();
        IporMath.divisionInt(-1, 0);
        vm.expectRevert();
        IporMath.divisionInt(0, 0);
    }

    function assertDivision(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal {
        assertEq(IporMath.division(x, y), z);
    }

    function assetConvertWadToAssetDecimals(
        uint256 amount,
        uint256 decimals,
        uint256 result
    ) internal {
        assertEq(IporMath.convertWadToAssetDecimals(amount, decimals), result);
    }

    function assetConvertWadToAssetDecimalsWithoutRound(
        uint256 amount,
        uint256 decimals,
        uint256 result
    ) internal {
        assertEq(IporMath.convertWadToAssetDecimalsWithoutRound(amount, decimals), result);
    }

    function assetConvertToWad(
        uint256 amount,
        uint256 decimals,
        uint256 result
    ) internal {
        assertEq(IporMath.convertToWad(amount, decimals), result);
    }

    function assertDivisionInt(
        int256 x,
        int256 y,
        int256 z
    ) internal {
        assertEq(IporMath.divisionInt(x, y), z);
    }

    function assertDivisionWithoutRound(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal {
        assertEq(IporMath.divisionWithoutRound(x, y), z);
    }
}
