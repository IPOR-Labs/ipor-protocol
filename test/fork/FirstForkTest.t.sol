// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IIpToken.sol";
import "./IAsset.sol";

contract FirstForkTest is TestForkCommons {
    function testDAI() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        uint256 balanceIpDaiBefore = ERC20(ipDAI).balanceOf(user);
        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        // when
        vm.prank(user);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(user, 10_000e18);

        // then
        uint256 balanceIpDaiAfter = ERC20(ipDAI).balanceOf(user);
        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);

        console2.log("balanceIpDaiBefore", balanceIpDaiBefore);
        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceIpDaiAfter", balanceIpDaiAfter);
        console2.log("balanceDaiAfter", balanceDaiAfter);
    }

    function testUSDC() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(USDC, user, 500_000e6);

        uint256 balanceIpUsdcBefore = ERC20(ipUSDC).balanceOf(user);
        uint256 balanceUsdcBefore = ERC20(USDC).balanceOf(user);

        // when
        vm.prank(user);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityUsdc(user, 10_000e6);

        // then
        uint256 balanceIpUsdcAfter = ERC20(ipUSDC).balanceOf(user);
        uint256 balanceUsdcAfter = ERC20(USDC).balanceOf(user);

        console2.log("balanceIpUsdcBefore", balanceIpUsdcBefore);
        console2.log("balanceUsdcBefore", balanceUsdcBefore);
        console2.log("balanceIpUsdcAfter", balanceIpUsdcAfter);
        console2.log("balanceUsdcAfter", balanceUsdcAfter);
    }

    function testUSDT() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        IAsset(USDT).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(USDT, user, 500_000e6);

        uint256 balanceIpUsdtBefore = ERC20(ipUSDT).balanceOf(user);
        uint256 balanceUsdtBefore = IAsset(USDT).balanceOf(user);

        // when
        vm.prank(user);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityUsdt(user, 10_000e6);

        // then
        uint256 balanceIpUsdtAfter = ERC20(ipUSDT).balanceOf(user);
        uint256 balanceUsdtAfter = IAsset(USDT).balanceOf(user);

        console2.log("balanceIpUsdtBefore", balanceIpUsdtBefore);
        console2.log("balanceUsdtBefore", balanceUsdtBefore);
        console2.log("balanceIpUsdtAfter", balanceIpUsdtAfter);
        console2.log("balanceUsdtAfter", balanceUsdtAfter);
    }
}
