// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract RedeemStEth is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();

        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, 1_000e18);
    }

    function testShouldRevertWhen0Amount() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userOne, 0);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint redeemAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes(IporErrors.WRONG_ADDRESS));
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(address(0), redeemAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldRevertWhenAmountBiggerThenBalance() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userOne, 10_000e18);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldBeAbleToRedeem() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();
        uint redeemAmount = 100e18;

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userOne, redeemAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertTrue(userStEthBalanceBefore < userStEthBalanceAfter, "user balance of stEth should increase");
        assertTrue(userIpstEthBalanceBefore > userIpstEthBalanceAfter, "user ipstEth balance should decrease");
        assertTrue(exchangeRateBefore < exchangeRateAfter, "exchange rate should increase");
    }

    function testShouldBeAbleToRedeemWhenBeneficiaryIsNotSender() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userTwoStEthBalanceBefore = IStETH(stEth).balanceOf(userTwo);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();
        uint redeemAmount = 100e18;

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userTwo, redeemAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userTwoStEthBalanceAfter = IStETH(stEth).balanceOf(userTwo);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertTrue(userTwoStEthBalanceBefore < userTwoStEthBalanceAfter, "user balance of stEth should increase");
        assertTrue(userIpstEthBalanceBefore > userIpstEthBalanceAfter, "user ipstEth balance should decrease");
        assertTrue(exchangeRateBefore < exchangeRateAfter, "exchange rate should increase");
    }
}