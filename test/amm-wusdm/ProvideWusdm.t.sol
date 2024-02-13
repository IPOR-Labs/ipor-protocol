// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./WusdmTestForkCommon.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProvideWusdmTest is WusdmTestForkCommon {

    address userOne;

    function setUp() public {
        _init();
        userOne = _getUserAddress(22);
        _setupUser(userOne, 100_000 * 1e18);
    }

    function testShouldExchangeRateBe1WhenNoProvideStEth() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given

        uint userUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userOne, 0);

        // then
        uint userUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userOne);

        assertEq(userUsdmBalanceBefore, userUsdmBalanceAfter, "user balance of usdm should not change");
        assertEq(userIpUsdmBalanceBefore, userIpUsdmBalanceAfter, "user ipusdm balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(address(0), provideAmount);

        // then
        uint userUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userOne);

        assertEq(userUsdmBalanceBefore, userUsdmBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpUsdmBalanceBefore, userIpUsdmBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideStEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userOne);
        uint ammTreasuryUsdmBalanceBefore = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);
        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userOne, provideAmount);

        // then
        uint userUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userOne);
        uint ammTreasuryUsdmBalanceAfter = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);

        uint exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertEq(userUsdmBalanceBefore - provideAmount, userUsdmBalanceAfter, "user balance of usdm should decrease");
        assertEq(
            userIpUsdmBalanceBefore + provideAmount,
            userIpUsdmBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userIpUsdmBalanceAfter, provideAmount, "user ipUsdm balance should be equal to provideAmount");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            10000000000000000000,
            "amm treasury balance should be 10000000000000000000"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            110000000000000000000,
            "amm treasury balance should be 110000000000000000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideUsdmToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userOne);
        uint userTwoUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceBefore = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);

        // then
        uint userOneUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userOne);
        uint userTwoUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceAfter = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);
        uint exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertEq(
            userOneUsdmBalanceBefore - provideAmount,
            userOneUsdmBalanceAfter,
            "user balance of usdm should decrease"
        );
        assertEq(userOneIpUsdmBalanceBefore, userOneIpUsdmBalanceAfter, "user ipUsdm balance should not change");
        assertEq(userTwoUsdmBalanceBefore, userTwoUsdmBalanceAfter, "user balance of usdm should not change");
        assertEq(
            userTwoIpUsdmBalanceBefore + provideAmount,
            userTwoIpUsdmBalanceAfter,
            "user ipusdm balance should increase"
        );
        assertEq(userTwoIpUsdmBalanceAfter, provideAmount, "user ipusdm balance should be equal to provideAmount");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            10000000000000000000,
            "amm treasury balance should be 10000000000000000000"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            110000000000000000000,
            "amm treasury balance should be 110000000000000000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesUsdm() external {
        // given

        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userOne);
        uint userTwoUsdmBalanceBefore = IERC20(WUSDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceBefore = IERC20(ipWusdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceBefore = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);
        }

        // then
        uint userOneUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userOne);
        uint userTwoUsdmBalanceAfter = IERC20(WUSDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceAfter = IERC20(ipWusdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceAfter = IERC20(WUSDM).balanceOf(ammTreasuryWusdmProxy);
        uint exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertEq(
            userOneUsdmBalanceBefore,
            98450085452308585847783,
            "user balance of Usdm should be 98450085452308585847783"
        );
        assertEq(
            userOneUsdmBalanceAfter,
            98350085452308585847783,
            "user balance of Usdm should be 98350085452308585847783"
        );
        assertEq(
            userOneIpUsdmBalanceBefore + provideAmount * 10,
            userOneIpUsdmBalanceAfter,
            "user ipUsdm balance should increase"
        );
        assertEq(
            userTwoUsdmBalanceBefore,
            98450085452308585847783,
            "user balance of Usdm should be 98450085452308585847783"
        );
        assertEq(
            userTwoUsdmBalanceAfter,
            98350085452308585847783,
            "user balance of Usdm should be 98350085452308585847783"
        );
        assertEq(
            userTwoIpUsdmBalanceBefore + provideAmount * 10,
            userTwoIpUsdmBalanceAfter,
            "user ipUsdm balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            10000000000000000000,
            "amm treasury balance should be 10000000000000000000"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            210000000000000000000,
            "amm treasury balance should be 210000000000000000000"
        );
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint provideAmount = 20_001e18;
        vm.startPrank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(WUSDM, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userOne, provideAmount);
    }

    function testShouldEmitProvideLiquidityWusdmToAmmPoolWusdmBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();
        uint256 ipTokenAmount = IporMath.division(provideAmount * 1e18, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.ProvideLiquidity(
            WUSDM,
            userOne,
            userTwo,
            ammTreasuryWusdmProxy,
            exchangeRateBefore,
            provideAmount,
            ipTokenAmount
        );

        // when
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);
    }

    function testShouldEmitRedeemUsdmBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);
        uint provideAmount = 100e18;
        uint256 amountWusdm = 99999999999999999999;
        uint256 redeemedAmountUsdm = 99499999999999999999;
        uint256 ipTokenAmount = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.Redeem(
            WUSDM,
            ammTreasuryWusdmProxy,
            userTwo,
            userOne,
            exchangeRate,
           amountWusdm,
            redeemedAmountUsdm,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).redeemFromAmmPoolWusdm(userOne,amountWusdm);
    }

        function testShouldRevertBecauseUserOneDoesntHaveIpUsdmTokensToRedeem() public {
            address userTwo = _getUserAddress(33);
            _setupUser(userTwo, 100_000 * 1e18);

        uint provideAmount = 100e18;
            uint256 amountWusdm = 99999999999999999999;

            vm.prank(userOne);
            IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);

            /// @dev userOne provide liquidity on behalf of userTwo
            vm.prank(userOne);
            //then
            vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));

            //when
            IAmmPoolsServiceWusdm(IporProtocolRouterProxy).redeemFromAmmPoolWusdm(userTwo,amountWusdm);
        }

        function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
            //given
            address userTwo = _getUserAddress(33);
            uint provideAmount = 100e18;

            vm.prank(userOne);
            //then
            vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
            //when
            IAmmPoolsServiceWusdm(ammPoolsServiceWusdm).provideLiquidityWusdmToAmmPoolWusdm(userTwo, provideAmount);
        }

}
