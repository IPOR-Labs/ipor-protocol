// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./WeEthTestForkCommon.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import {IAmmPoolsLensBaseV1} from "../../contracts/base/interfaces/IAmmPoolsLensBaseV1.sol";

contract UsdmForkAmmWstEthExchangeRateTest is WeEthTestForkCommon {
    function testShouldNotChangeExchangeRateWhenProvideLiquidityWeEthToAmmPoolWeEthForWeEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityToAmmPoolWeEthForWeEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, weETH, user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityToAmmPoolWeEthForEEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, eETH, user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityToAmmPoolWeEthForWEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, wETH, user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityToAmmPoolWeEthForEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity{value: provideAmount}(
            weETH,
            ETH,
            user,
            provideAmount
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }


        function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeUsdm() public {
            // given
            _init();
            address user = _getUserAddress(22);
            _setupUser(user, 1000 * 1e18);

            uint256 provideAmount = 1e18;

            uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

            // when
            vm.startPrank(user);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(user, provideAmount);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(user, provideAmount);
            uint256 ipWeEthAmount = IERC20(ipWeEth).balanceOf(user);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).redeemFromAmmPoolWeEth(user, provideAmount);
            vm.stopPrank();

            //then
            uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

            assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
        }

        function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROWeEth()
            public
        {
            // given
            _init();
            vm.startPrank(IporProtocolOwner);
            _createAmmPoolsServiceWeEth(0);
            _updateIporRouterImplementation();
            vm.stopPrank();

            address user = _getUserAddress(22);
            _setupUser(user, 1000 * 1e18);

            uint256 provideAmount = 100e18;

            uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

            // when
            vm.startPrank(user);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(user, provideAmount);

            uint256 ipWeEthAmount = IERC20(ipWeEth).balanceOf(user);
            IAmmPoolsServiceWeEth(IporProtocolRouterProxy).redeemFromAmmPoolWeEth(user, ipWeEthAmount);
            vm.stopPrank();

            //then
            uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(IporProtocolRouterProxy).getIpTokenExchangeRate(weETH);

            assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
        }
}
