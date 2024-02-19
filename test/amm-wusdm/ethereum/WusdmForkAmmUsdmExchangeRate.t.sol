// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./WusdmTestForkCommon.sol";
import "../../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../contracts/interfaces/types/AmmTypes.sol";

contract WusdmForkAmmWstEthExchangeRateTest is WusdmTestForkCommon {

    function testShouldNotChangeExchangeRateWhenProvideLiquidityWusdmToAmmPoolWusdmForUsdm() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 *1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeUsdm() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(user, provideAmount);
        uint256 ipUsdmAmount = IERC20(ipWusdm).balanceOf(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).redeemFromAmmPoolWusdm(user, ipUsdmAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROUsdm()
        public
    {
        // given
        _init();
        vm.startPrank(IporProtocolOwner);
        _createAmmPoolsServiceWusdm(0);
        _updateIporRouterImplementation();
        vm.stopPrank();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 100e18;

        uint256 exchangeRateBefore = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(user, provideAmount);

        uint256 ipUsdmAmount = IERC20(ipWusdm).balanceOf(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).redeemFromAmmPoolWusdm(user, ipUsdmAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensWusdm(IporProtocolRouterProxy).getIpWusdmExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }
}