// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract ProvideWEth is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();
    }

    function testShouldRevertWhen0Amount() external {
        // given
        uint userWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(IporErrors.VALUE_NOT_GREATER_THAN_ZERO));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, 0);

        // then
        uint userWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userWEthBalanceBefore, userWEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userwEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes(IporErrors.WRONG_ADDRESS));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(address(0), provideAmount);

        // then
        uint userwEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userwEthBalanceBefore, userwEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldProvideWEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);

        // then
        uint userWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userWEthBalanceAfter, 49_900e18, "user balance of wEth should be 49_900e18");
        assertEq(userIpEthBalanceBefore, 0, "user ipEth balance should be 0");
        assertEq(userIpEthBalanceAfter, 99999999999999999999, "user ipEth balance should be 99999999999999999999");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999998,
            "amm treasury balance should be 99999999999999999998"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideStEthToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        uint userOneWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userOneIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint userTwoWEthBalanceBefore = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);

        // then
        uint userOneWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoWEthBalanceAfter = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userOneWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userOneWEthBalanceAfter, 49_900e18, "user balance of wEth should be 49_900e18");
        assertEq(userOneIpEthBalanceBefore, userOneIpEthBalanceAfter, "user ipEth balance should not change");
        assertEq(userTwoWEthBalanceBefore, userTwoWEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userTwoIpEthBalanceBefore, 0, "user ipEth balance should be 0 before providing liquidity");
        assertEq(
            userTwoIpEthBalanceAfter,
            99999999999999999999,
            "user ipEth balance should be 99999999999999999999 after providing liquidity"
        );
        assertEq(userTwoIpEthBalanceAfter, 99999999999999999999, "user ipEth balance should be 99999999999999999999");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999998,
            "amm treasury balance should be 99999999999999999998"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesStEth() external {
        // given
        uint userOneWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userTwoWEthBalanceBefore = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);
        }

        // then
        uint userOneWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoWEthBalanceAfter = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userOneWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userOneWEthBalanceAfter, 49900e18, "user balance of wEth should be 49900e18");
        assertEq(userOneIpEthBalanceAfter, 99_999999999999999998, "user ipEth balance should be 99_999999999999999998");
        assertEq(
            userTwoWEthBalanceBefore,
            50_000e18,
            "user balance of wEth should be 50_000e18"
        );
        assertEq(
            userTwoWEthBalanceAfter,
            49900e18,
            "user balance of wEth should be 49900e18"
        );
        assertEq(
            userTwoIpEthBalanceBefore + provideAmount * 10,
            userTwoIpEthBalanceAfter,
            "user ipEth balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            199999999999999999978,
            "amm treasury balance should be 199999999999999999978"
        );
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint provideAmount = 20_001e18;
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouter).setAmmPoolsParams(stEth, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);
    }

    function testShouldRevertWhenReachLidoLimit() public {
        // given
        uint provideAmount = 150_001e18; // inside Lido is limit to 150_000e18 eth deposit per day
        vm.startPrank(userOne);
        IWETH9(wEth).deposit{value: 150_000e18}();
        vm.stopPrank();

        // when
        vm.prank(userOne);
        vm.expectRevert(abi.encodeWithSelector(IAmmPoolsServiceEth.StEthSubmitFailed.selector, provideAmount));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);
    }

    // todo add tests for events
}
