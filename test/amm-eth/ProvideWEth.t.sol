// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract ProvideWEth is TestEthMarketCommons {
    event ProvideLiquidityEth(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 amountEth,
        uint256 amountStEth,
        uint256 ipTokenAmount
    );

    event RedeemStEth(
        uint256 timestamp,
        address ammTreasuryEth,
        address from,
        address beneficiary,
        uint256 exchangeRate,
        uint256 amountStEth,
        uint256 redeemedAmountStEth,
        uint256 ipTokenAmount
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();
    }

    function testShouldRevertWhen0Amount() external {
        // given
        uint userWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(IporErrors.VALUE_NOT_GREATER_THAN_ZERO));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, 0);

        // then
        uint userWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userWEthBalanceBefore, userWEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userwEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(address(0), provideAmount);

        // then
        uint userwEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userwEthBalanceBefore, userwEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideWEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userWEthBalanceBefore = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);

        // then
        uint userWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(userWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userWEthBalanceAfter, 49_900e18, "user balance of wEth should be 49_900e18");
        assertEq(userIpstEthBalanceBefore, 0, "user ipstEth balance should be 0");
        assertEq(userIpstEthBalanceAfter, 99999999999999999999, "user ipstEth balance should be 99999999999999999999");
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
        uint userOneIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoWEthBalanceBefore = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);

        // then
        uint userOneWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userOneIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoWEthBalanceAfter = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(userOneWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userOneWEthBalanceAfter, 49_900e18, "user balance of wEth should be 49_900e18");
        assertEq(userOneIpstEthBalanceBefore, userOneIpstEthBalanceAfter, "user ipstEth balance should not change");
        assertEq(userTwoWEthBalanceBefore, userTwoWEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userTwoIpstEthBalanceBefore, 0, "user ipstEth balance should be 0 before providing liquidity");
        assertEq(
            userTwoIpstEthBalanceAfter,
            99999999999999999999,
            "user ipstEth balance should be 99999999999999999999 after providing liquidity"
        );
        assertEq(
            userTwoIpstEthBalanceAfter,
            99999999999999999999,
            "user ipstEth balance should be 99999999999999999999"
        );
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
        uint userTwoIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);
        }

        // then
        uint userOneWEthBalanceAfter = IWETH9(wEth).balanceOf(userOne);
        uint userOneIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoWEthBalanceAfter = IWETH9(wEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(userOneWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userOneWEthBalanceAfter, 49900e18, "user balance of wEth should be 49900e18");
        assertEq(
            userOneIpstEthBalanceAfter,
            99_999999999999999998,
            "user ipstEth balance should be 99_999999999999999998"
        );
        assertEq(userTwoWEthBalanceBefore, 50_000e18, "user balance of wEth should be 50_000e18");
        assertEq(userTwoWEthBalanceAfter, 49900e18, "user balance of wEth should be 49900e18");
        assertEq(
            userTwoIpstEthBalanceBefore + provideAmount * 10,
            userTwoIpstEthBalanceAfter,
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
        vm.expectRevert(
            abi.encodeWithSelector(
                IAmmPoolsServiceEth.StEthSubmitFailed.selector,
                provideAmount,
                AmmErrors.STETH_SUBMIT_FAILED
            )
        );
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userOne, provideAmount);
    }

    function testShouldEmitProvideLiquidityStEthBeneficiaryIsNotSender() public {
        // given
        uint provideAmount = 100e18;

        uint256 amountStEth = 99999999999999999999;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();
        uint256 ipTokenAmount = IporMath.division(amountStEth * 1e18, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);

        //then
        emit ProvideLiquidityEth(
            block.timestamp,
            userOne,
            userTwo,
            ammTreasuryEth,
            exchangeRateBefore,
            provideAmount,
            amountStEth,
            ipTokenAmount
        );

        // when
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);
    }

    function testShouldEmitRedeemStEthBeneficiaryIsNotSender() public {
        // given
        uint provideAmount = 100e18;
        uint256 amountStEth = 99999999999999999999;
        uint256 redeemedAmountStEth = 99499999999999999999;
        uint256 ipTokenAmount = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit RedeemStEth(
            block.timestamp,
            ammTreasuryEth,
            userTwo,
            userOne,
            exchangeRate,
            amountStEth,
            redeemedAmountStEth,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userOne, amountStEth);
    }

    function testShouldRevertBecauseUserOneDoesntHaveIpstEthTokensToRedeem() public {
        uint provideAmount = 100e18;
        uint256 amountStEth = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityWEth(userTwo, provideAmount);

        /// @dev userOne provide liquidity on behalf of userTwo
        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));

        //when
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userTwo, amountStEth);
    }

    function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
        //given
        uint provideAmount = 100e18;

        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        //when
        IAmmPoolsServiceEth(ammPoolsServiceEth).provideLiquidityWEth(userTwo, provideAmount);
    }
}
