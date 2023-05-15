// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicCalculateQuasiInterest is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateSwapAmountSimpleCase1000Leverage() public {
        //given
        uint256 timeToMaturityInDays = 18;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e16;

        //when
        (uint256 collateral, uint256 notional, uint256 openingFee) = _iporSwapLogic
            .calculateSwapAmount(
                timeToMaturityInDays,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );

        //then
        assertEq(openingFee, 320366972477064220046, "incorrect opening fee");
        assertEq(collateral, 649633027522935779954, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmountSimpleCase10Leverage() public {
        //given
        uint256 timeToMaturityInDays = 18;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 10e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e16;

        //when
        (uint256 collateral, uint256 notional, uint256 openingFee) = _iporSwapLogic
            .calculateSwapAmount(
                timeToMaturityInDays,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );

        //then
        assertEq(openingFee, 4760087241003271064, "incorrect opening fee");
        assertEq(collateral, 965239912758996728936, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmount100OpeningFeeRate() public {
        //given
        uint256 timeToMaturityInDays = 18;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e18;

        //when
        (uint256 collateral, uint256 notional, uint256 openingFee) = _iporSwapLogic
            .calculateSwapAmount(
                timeToMaturityInDays,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );

        //then
        assertEq(openingFee, 950721481078137762048, "incorrect opening fee");
        assertEq(collateral, 19278518921862237952, "incorrect collateral");
        assertEq(
            totalAmount - liquidationDepositAmount - iporPublicationFeeAmount,
            openingFee + collateral,
            "incorrect total amount"
        );
    }

    function testShouldCalculateSwapAmountZeroPercentOpeningFeeRate() public {
        //given
        uint256 timeToMaturityInDays = 18;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 1000e18;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 0;

        //when
        (uint256 collateral, uint256 notional, uint256 openingFee) = _iporSwapLogic
            .calculateSwapAmount(
                timeToMaturityInDays,
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
        uint256 timeToMaturityInDays = 18;
        uint256 totalAmount = 1000e18;
        uint256 leverage = 0;
        uint256 liquidationDepositAmount = 20e18;
        uint256 iporPublicationFeeAmount = 10e18;
        uint256 openingFeeRate = 1e18;

        //when
        (uint256 collateral, uint256 notional, uint256 openingFee) = _iporSwapLogic
        .calculateSwapAmount(
            timeToMaturityInDays,
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
