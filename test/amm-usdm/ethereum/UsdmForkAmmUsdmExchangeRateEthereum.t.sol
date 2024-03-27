// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../contracts/interfaces/types/AmmTypes.sol";
import {UsdmTestForkCommonEthereum} from "./UsdmTestForkCommonEthereum.sol";
import {IAmmPoolsLensUsdm} from "../../../contracts/amm-usdm/interfaces/IAmmPoolsLensUsdm.sol";
import {IAmmPoolsServiceUsdm} from "../../../contracts/amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";

contract UsdmForkAmmUsdmExchangeRateEthereumTest is UsdmTestForkCommonEthereum {

    function testShouldNotChangeExchangeRateWhenProvideLiquidityUsdmToAmmPoolUsdmForUsdm() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 100_000 * 1e18);

        uint256 provideAmount = 10_000 * 1e18;

        uint256 exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeUsdm() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(user, provideAmount);
        uint256 ipUsdmAmount = IERC20(ipUsdm).balanceOf(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).redeemFromAmmPoolUsdm(user, ipUsdmAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROUsdm()
    public
    {
        // given
        _init();
        vm.startPrank(IporProtocolOwner);
        _createAmmPoolsServiceUsdm(0);
        _updateIporRouterImplementation();
        vm.stopPrank();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 100e18;

        uint256 exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(user, provideAmount);

        uint256 ipUsdmAmount = IERC20(ipUsdm).balanceOf(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).redeemFromAmmPoolUsdm(user, ipUsdmAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }
}