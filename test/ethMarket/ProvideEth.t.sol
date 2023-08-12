// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract ProvideEth is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();
    }

    receive() external payable {}

    function testShouldRevertWhen0Amount() external {
        // given
        uint userEthBalanceBefore = userOne.balance;
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);

        // when
        vm.prank(userOne);
        vm.expectRevert();
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: 10e18}(userOne, 0);

        // then
        uint userEthBalanceAfter = userOne.balance;
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userEthBalanceBefore, userEthBalanceAfter, "user balance of Eth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldRevertWhen0EthSend() external {
        // given
        uint userEthBalanceBefore = userOne.balance;
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes(IporErrors.VALUE_NOT_GREATER_THAN_ZERO));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: 0}(userOne, 1e18);

        // then
        uint userEthBalanceAfter = userOne.balance;
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userEthBalanceBefore, userEthBalanceAfter, "user balance of Eth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userEthBalanceBefore = userOne.balance;
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert();
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: 10e18}(address(0), provideAmount);

        // then
        uint userEthBalanceAfter = userOne.balance;
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userEthBalanceBefore, userEthBalanceAfter, "user balance of Eth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldProvideEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userEthBalanceBefore = userOne.balance;
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userOne, provideAmount);

        // then
        uint userWEthBalanceAfter = userOne.balance;
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userEthBalanceBefore, 900_000e18, "user balance of Eth should be 900_000e18");
        assertEq(userWEthBalanceAfter, 899_900e18, "user balance of Eth should be 899_900e18");
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

    function testShouldProvideEthToOwnAddressWhenBeneficiaryIsSenderAndReturnRestOfEth() external {
        // given
        uint userEthBalanceBefore = userOne.balance;
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount + 10e18}(
            userOne,
            provideAmount
        );

        // then
        uint userWEthBalanceAfter = userOne.balance;
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userEthBalanceBefore, 900_000e18, "user balance of Eth should be 900_000e18");
        assertEq(userWEthBalanceAfter, 899_900e18, "user balance of Eth should be 899_900e18");
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
        uint userOneEthBalanceBefore = userOne.balance;
        uint userOneIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint userTwoEthBalanceBefore = userTwo.balance;
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userTwo, provideAmount);

        // then
        uint userOneEthBalanceAfter = userOne.balance;
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoEthBalanceAfter = userTwo.balance;
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userOneEthBalanceBefore, 900_000e18, "user balance of Eth should be 900_000e18");
        assertEq(userOneEthBalanceAfter, 899_900e18, "user balance of Eth should be 899_900e18");
        assertEq(userOneIpEthBalanceBefore, userOneIpEthBalanceAfter, "user ipEth balance should not change");
        assertEq(userTwoEthBalanceBefore, userTwoEthBalanceAfter, "user balance of stEth should not change");
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

    function testShouldProvide10TimesEth() external {
        // given
        uint userOneEthBalanceBefore = userOne.balance;
        uint userTwoEthBalanceBefore = userTwo.balance;
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userTwo, provideAmount);
        }

        // then
        uint userOneEthBalanceAfter = userOne.balance;
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoEthBalanceAfter = userTwo.balance;
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(userOneEthBalanceBefore, 900_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userOneEthBalanceAfter, 899_900e18, "user balance of wEth should be 49900e18");
        assertEq(userOneIpEthBalanceAfter, 99_999999999999999998, "user ipEth balance should be 99_999999999999999998");
        assertEq(userTwoEthBalanceBefore, 900_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userTwoEthBalanceAfter, 899_900e18, "user balance of wEth should be 49900e18");
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
        vm.expectRevert();
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userOne, provideAmount);
    }

    function testShouldRevertWhenReachLidoLimit() public {
        // given
        uint provideAmount = 150_001e18; // inside Lido is limit to 150_000e18 eth deposit per day

        // when
        vm.prank(userOne);
        vm.expectRevert();
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityEth{value: provideAmount}(userOne, provideAmount);
    }
    // todo add tests for events
}
