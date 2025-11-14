// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {DataUtils} from "../../utils/DataUtils.sol";
import "../../../test/TestCommons.sol";
import "../../mocks/MockSwapLogicBaseV1.sol";

contract IporSwapLogicCalculateInterest is TestCommons, DataUtils {
    MockSwapLogicBaseV1 internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockSwapLogicBaseV1();
    }

    function testShouldCalculateSwapAmountSimpleCase1000Leverage() public {
        //given
        IporTypes.SwapTenor tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e16;

        //when
        (uint256 collateral, , uint256 openingFee) = _iporSwapLogic.calculateSwapAmount(
            tenor,
            totalAmount,
            leverage,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeeRate
        );

        //then
        assertEq(openingFee, 421085271317829457454, "incorrect opening fee");
        assertEq(collateral, 548914728682170542546, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmountSimpleCase10Leverage() public {
        //given
        IporTypes.SwapTenor tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 10e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e16;

        //when
        (uint256 collateral, , uint256 openingFee) = _iporSwapLogic.calculateSwapAmount(
            tenor,
            totalAmount,
            leverage,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeeRate
        );

        //then
        assertEq(openingFee, 7384448069603045356, "incorrect opening fee");
        assertEq(collateral, 962615551930396954644, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmount100OpeningFeeRate() public {
        //given
        IporTypes.SwapTenor tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e18;

        //when
        (uint256 collateral, , uint256 openingFee) = _iporSwapLogic.calculateSwapAmount(
            tenor,
            totalAmount,
            leverage,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeeRate
        );

        //then
        assertEq(openingFee, 957518068041600564075, "incorrect opening fee");
        assertEq(collateral, 12481931958399435925, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmountZeroPercentOpeningFeeRate() public {
        //given
        IporTypes.SwapTenor tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 0;

        //when
        (uint256 collateral, , uint256 openingFee) = _iporSwapLogic.calculateSwapAmount(
            tenor,
            totalAmount,
            leverage,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeeRate
        );

        //then
        assertEq(openingFee, 0, "incorrect opening fee");
        assertEq(collateral, 970000000000000000000, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmountOpeningFeeRateLeverageZero() public {
        //given
        IporTypes.SwapTenor tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 0;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e18;

        //when
        (uint256 collateral, , uint256 openingFee) = _iporSwapLogic.calculateSwapAmount(
            tenor,
            totalAmount,
            leverage,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeeRate
        );

        //then
        assertEq(openingFee, 0, "incorrect opening fee");
        assertEq(collateral, 970000000000000000000, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }
}
