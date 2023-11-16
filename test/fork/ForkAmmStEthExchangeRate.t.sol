// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthExchangeRateTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldNotChnageExchangeRateWhenProvideLiquidityStEthForStEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceEth(iporProtocolRouterProxy).provideLiquidityStEth(user, provideAmount);

        //then
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChnageExchangeRateWhenProvideLiquidityStEthForWEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceEth(iporProtocolRouterProxy).provideLiquidityWEth(user, provideAmount);

        //then
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChnageExchangeRateWhenProvideLiquidityStEthForEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceEth(iporProtocolRouterProxy).provideLiquidityEth{value: provideAmount}(user, provideAmount);

        //then
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenOpenSwap() public {}

    function testShouldNotChnageExchangeRateWhenProvideLiquidityAndRedeemStEthForStEth() public {}

    function testShouldNotChangeExchangeRateWhenChangeStorageBalanceCase1() public {}

    function testShouldChangeUnderlyingValueOfIpTokenWhenSomeoneElseRedeemBacauseOfRedeemFee() public {}

    function testShouldChangeUnderlyingValueOfIpTokenWhenSomeoneCloseSwapBecauseOfFee() public {}
}
