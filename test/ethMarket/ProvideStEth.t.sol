// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract ProvideStEthTest is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();
    }

    function testShouldExchangeRateBe1WhenNoProvideStEth() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, 0);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(address(0), provideAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpEthBalanceBefore, userIpEthBalanceAfter, "user ipEth balance should not change");
    }

    function testShouldProvideStEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(
            userStEthBalanceBefore - provideAmount,
            userStEthBalanceAfter,
            "user balance of stEth should decrease"
        );
        assertEq(userIpEthBalanceBefore + provideAmount, userIpEthBalanceAfter, "user ipEth balance should increase");
        assertEq(userIpEthBalanceAfter, provideAmount, "user ipEth balance should be equal to provideAmount");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999999,
            "amm treasury balance should be 99999999999999999999"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideStEthToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        uint userOneStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userOneIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint userTwoStEthBalanceBefore = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);

        // then
        uint userOneStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoStEthBalanceAfter = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(
            userOneStEthBalanceBefore - provideAmount,
            userOneStEthBalanceAfter,
            "user balance of stEth should decrease"
        );
        assertEq(userOneIpEthBalanceBefore, userOneIpEthBalanceAfter, "user ipEth balance should not change");
        assertEq(userTwoStEthBalanceBefore, userTwoStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(
            userTwoIpEthBalanceBefore + provideAmount,
            userTwoIpEthBalanceAfter,
            "user ipEth balance should increase"
        );
        assertEq(userTwoIpEthBalanceAfter, provideAmount, "user ipEth balance should be equal to provideAmount");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999999,
            "amm treasury balance should be 99999999999999999999"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesStEth() external {
        // given
        uint userOneStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userOneIpEthBalanceBefore = IERC20(ipEth).balanceOf(userOne);
        uint userTwoStEthBalanceBefore = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceBefore = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);
        }

        // then
        uint userOneStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userOneIpEthBalanceAfter = IERC20(ipEth).balanceOf(userOne);
        uint userTwoStEthBalanceAfter = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpEthBalanceAfter = IERC20(ipEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate();

        assertEq(
            userOneStEthBalanceBefore,
            49999999999999999999999,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userOneStEthBalanceAfter,
            49900000000000000000009,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userOneIpEthBalanceBefore + provideAmount * 10,
            userOneIpEthBalanceAfter,
            "user ipEth balance should increase"
        );
        assertEq(
            userTwoStEthBalanceBefore,
            49999999999999999999999,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userTwoStEthBalanceAfter,
            49900000000000000000009,
            "user balance of stEth should be 49999999999999999999999"
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
            199999999999999999979,
            "amm treasury balance should be 199999999999999999979"
        );

        console2.log("IERC20(ipEth): ", IERC20(ipEth).totalSupply());
        console2.log("IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate(): ", IAmmPoolsLensEth(iporProtocolRouter).getIpEthExchangeRate());
        console2.log("IStETH(stEth).balanceOf(ammTreasuryEth): ", IStETH(stEth).balanceOf(ammTreasuryEth));
        // 49_999 999999999999999999 (userOne Balance)
        //-   100 000000000000000000 (transfer to ammTreasury)
        //-----------------------------
        // 49_900 000000000000000009 (userOne balance after)
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
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);
    }

    // todo add tests for events
}
