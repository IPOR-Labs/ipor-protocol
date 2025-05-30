// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "./WeEthTestForkCommon.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProvideWeEthTest is WeEthTestForkCommon {
    address userOne;

    function setUp() public {
        _init();
        userOne = _getUserAddress(22);
        _setupUser(userOne, 100_000 * 1e18);
    }

    function testShouldExchangeRateBe1WhenNoProvideWeEth() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given

        uint userWeEthBalanceBefore = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userOne, 0);

        // then
        uint userWeEthBalanceAfter = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userOne);

        assertEq(userWeEthBalanceBefore, userWeEthBalanceAfter, "user balance of usdm should not change");
        assertEq(userIpWeEthBalanceBefore, userIpWeEthBalanceAfter, "user ipWeEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userWeEthBalanceBefore = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(address(0), provideAmount);

        // then
        uint userWeEthBalanceAfter = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userOne);

        assertEq(userWeEthBalanceBefore, userWeEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpWeEthBalanceBefore, userIpWeEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideWeEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userWeEthBalanceBefore = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userOne);
        uint ammTreasuryWeEthBalanceBefore = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);
        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userOne, provideAmount);

        // then
        uint userWeEthBalanceAfter = IERC20(weETH).balanceOf(userOne);
        uint userIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userOne);
        uint ammTreasuryWeEthBalanceAfter = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);

        uint exchangeRateAfter = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        assertEq(
            userWeEthBalanceBefore - provideAmount,
            userWeEthBalanceAfter,
            "user balance of weEth should decrease"
        );
        assertEq(
            userIpWeEthBalanceBefore + provideAmount,
            userIpWeEthBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userIpWeEthBalanceAfter, provideAmount, "user ipWeEth balance should be equal to provideAmount");
        assertEq(ammTreasuryWeEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryWeEthBalanceAfter,
            100000000000000000000,
            "amm treasury balance should be 100000000000000000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideWeEthToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneWeEthBalanceBefore = IERC20(weETH).balanceOf(userOne);
        uint userOneIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userOne);
        uint userTwoWeEthBalanceBefore = IERC20(weETH).balanceOf(userTwo);
        uint userTwoIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userTwo);
        uint ammTreasuryWeEthBalanceBefore = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);

        // then
        uint userOneWeEthBalanceAfter = IERC20(weETH).balanceOf(userOne);
        uint userOneIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userOne);
        uint userTwoWeEthBalanceAfter = IERC20(weETH).balanceOf(userTwo);
        uint userTwoIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userTwo);
        uint ammTreasuryWeEthBalanceAfter = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);
        uint exchangeRateAfter = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        assertEq(
            userOneWeEthBalanceBefore - provideAmount,
            userOneWeEthBalanceAfter,
            "user balance of usdm should decrease"
        );
        assertEq(userOneIpWeEthBalanceBefore, userOneIpWeEthBalanceAfter, "user ipWeEth balance should not change");
        assertEq(userTwoWeEthBalanceBefore, userTwoWeEthBalanceAfter, "user balance of usdm should not change");
        assertEq(
            userTwoIpWeEthBalanceBefore + provideAmount,
            userTwoIpWeEthBalanceAfter,
            "user ipWeEth balance should increase"
        );
        assertEq(userTwoIpWeEthBalanceAfter, provideAmount, "user ipWeEth balance should be equal to provideAmount");
        assertEq(ammTreasuryWeEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryWeEthBalanceAfter,
            100000000000000000000,
            "amm treasury balance should be 100000000000000000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesWeEth() external {
        // given

        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneWeEthBalanceBefore = IERC20(weETH).balanceOf(userOne);
        uint userOneIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userOne);
        uint userTwoWeEthBalanceBefore = IERC20(weETH).balanceOf(userTwo);
        uint userTwoIpWeEthBalanceBefore = IERC20(ipWeEth).balanceOf(userTwo);
        uint ammTreasuryWeEthBalanceBefore = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);
        }

        // then
        uint userOneWeEthBalanceAfter = IERC20(weETH).balanceOf(userOne);
        uint userOneIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userOne);
        uint userTwoWeEthBalanceAfter = IERC20(weETH).balanceOf(userTwo);
        uint userTwoIpWeEthBalanceAfter = IERC20(ipWeEth).balanceOf(userTwo);
        uint ammTreasuryWeEthBalanceAfter = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);
        uint exchangeRateAfter = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();

        assertEq(
            userOneWeEthBalanceBefore,
            97062378226296843608896,
            "user balance of WeEth should be 97062378226296843608896"
        );
        assertEq(
            userOneWeEthBalanceAfter,
            96962378226296843608896,
            "user balance of WeEth should be 96962378226296843608896"
        );
        assertEq(
            userOneIpWeEthBalanceBefore + provideAmount * 10,
            userOneIpWeEthBalanceAfter,
            "user ipWeEth balance should increase"
        );
        assertEq(
            userTwoWeEthBalanceBefore,
            97062378226296843608896,
            "user balance of WeEth should be 97062378226296843608896"
        );
        assertEq(
            userTwoWeEthBalanceAfter,
            96962378226296843608896,
            "user balance of WeEth should be 96962378226296843608896"
        );
        assertEq(
            userTwoIpWeEthBalanceBefore + provideAmount * 10,
            userTwoIpWeEthBalanceAfter,
            "user ipWeEth balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertEq(ammTreasuryWeEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryWeEthBalanceAfter,
            200000000000000000000,
            "amm treasury balance should be 200000000000000000000"
        );
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint provideAmount = 20_001e18;
        vm.startPrank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(weETH, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userOne, provideAmount);
    }

    function testShouldEmitprovideLiquidityWeEthToAmmPoolWeEthBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWeEth(IporProtocolRouterProxy).getIpWeEthExchangeRate();
        uint256 ipTokenAmount = IporMath.division(provideAmount * 1e18, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.ProvideLiquidity(
            weETH,
            userOne,
            userTwo,
            ammTreasuryWeEthProxy,
            exchangeRateBefore,
            provideAmount,
            ipTokenAmount
        );

        // when
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);
    }

    function testShouldEmitRedeemWeEthBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);
        uint provideAmount = 100e18;
        uint256 amountWeEth = 99999999999999999999;
        uint256 redeemedAmountWeEth = 99499999999999999999;
        uint256 ipTokenAmount = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.Redeem(
            weETH,
            ammTreasuryWeEthProxy,
            userTwo,
            userOne,
            exchangeRate,
            amountWeEth,
            redeemedAmountWeEth,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).redeemFromAmmPoolWeEth(userOne, amountWeEth);
    }

    function testShouldRevertBecauseUserOneDoesntHaveIpWeEthTokensToRedeem() public {
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint provideAmount = 100e18;
        uint256 amountWeEth = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);

        /// @dev userOne provide liquidity on behalf of userTwo
        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));

        //when
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).redeemFromAmmPoolWeEth(userTwo, amountWeEth);
    }

    function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
        //given
        address userTwo = _getUserAddress(33);
        uint provideAmount = 100e18;

        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        //when
        IAmmPoolsServiceWeEth(ammPoolsServiceWeEth).provideLiquidityWeEthToAmmPoolWeEth(userTwo, provideAmount);
    }
}
