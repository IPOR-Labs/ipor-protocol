// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IIpToken.sol";

contract OpenSwapForkTest is TestForkCommons {
    function test27D() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(user, 10_000e18, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            DAI,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceDaiAfter", balanceDaiAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 27 days);

        IporTypes.AccruedIpor memory accruedIporAfter27Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter27Days", accruedIporAfter27Days.indexValue);
        console2.log("ibtPriceAfter27Days", accruedIporAfter27Days.ibtPrice);

        (uint256 totalCountAfter27Days, IAmmSwapsLens.IporSwap[] memory swapsAfter27Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter27Days = swapsAfter27Days[0];
        console2.log("swapAfter27Days.collateral", swapAfter27Days.collateral);
        console2.log("swapAfter27Days.openTimestamp", swapAfter27Days.openTimestamp);
        console2.log("swapAfter27Days.endTimestamp", swapAfter27Days.endTimestamp);
        console2.log("swapAfter27Days.fixedInterestRate", swapAfter27Days.fixedInterestRate);
        console2.log("swapAfter27Days.ibtQuantity", swapAfter27Days.ibtQuantity);
        console2.log("swapAfter27Days.notional", swapAfter27Days.notional);
        console2.log("swapAfter27Days.direction", swapAfter27Days.direction);
        console2.log("swapAfter27Days.leverage", swapAfter27Days.leverage);
        console2.logInt(swapAfter27Days.payoff);
    }

    function test59D() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed60daysDai(user, 10_000e18, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            DAI,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceDaiAfter", balanceDaiAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 59 days);

        IporTypes.AccruedIpor memory accruedIporAfter59Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter59Days", accruedIporAfter59Days.indexValue);
        console2.log("ibtPriceAfter59Days", accruedIporAfter59Days.ibtPrice);

        (uint256 totalCountAfter59Days, IAmmSwapsLens.IporSwap[] memory swapsAfter59Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter59Days = swapsAfter59Days[0];
        console2.log("swapAfter59Days.collateral", swapAfter59Days.collateral);
        console2.log("swapAfter59Days.openTimestamp", swapAfter59Days.openTimestamp);
        console2.log("swapAfter59Days.endTimestamp", swapAfter59Days.endTimestamp);
        console2.log("swapAfter59Days.fixedInterestRate", swapAfter59Days.fixedInterestRate);
        console2.log("swapAfter59Days.ibtQuantity", swapAfter59Days.ibtQuantity);
        console2.log("swapAfter59Days.notional", swapAfter59Days.notional);
        console2.log("swapAfter59Days.direction", swapAfter59Days.direction);
        console2.log("swapAfter59Days.leverage", swapAfter59Days.leverage);
        console2.logInt(swapAfter59Days.payoff);
    }

    function test89D() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed90daysDai(user, 10_000e18, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            DAI,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceDaiAfter", balanceDaiAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 89 days);

        IporTypes.AccruedIpor memory accruedIporAfter89Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter89Days", accruedIporAfter89Days.indexValue);
        console2.log("ibtPriceAfter89Days", accruedIporAfter89Days.ibtPrice);

        (uint256 totalCountAfter89Days, IAmmSwapsLens.IporSwap[] memory swapsAfter89Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter89Days = swapsAfter89Days[0];
        console2.log("swapAfter89Days.collateral", swapAfter89Days.collateral);
        console2.log("swapAfter89Days.openTimestamp", swapAfter89Days.openTimestamp);
        console2.log("swapAfter89Days.endTimestamp", swapAfter89Days.endTimestamp);
        console2.log("swapAfter89Days.fixedInterestRate", swapAfter89Days.fixedInterestRate);
        console2.log("swapAfter89Days.ibtQuantity", swapAfter89Days.ibtQuantity);
        console2.log("swapAfter89Days.notional", swapAfter89Days.notional);
        console2.log("swapAfter89Days.direction", swapAfter89Days.direction);
        console2.log("swapAfter89Days.leverage", swapAfter89Days.leverage);
        console2.logInt(swapAfter89Days.payoff);
    }

    function test27DWithIndexPublication() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(user, 10_000e18, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            DAI,
            user,
            0,
            10
        );

        vm.prank(oracleUpdater);
        IIporOracle(iporOracleProxy).updateIndex(DAI, 4e16);

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceDaiAfter", balanceDaiAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 27 days);

        IporTypes.AccruedIpor memory accruedIporAfter27Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter27Days", accruedIporAfter27Days.indexValue);
        console2.log("ibtPriceAfter27Days", accruedIporAfter27Days.ibtPrice);

        (uint256 totalCountAfter27Days, IAmmSwapsLens.IporSwap[] memory swapsAfter27Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter27Days = swapsAfter27Days[0];
        console2.log("swapAfter27Days.collateral", swapAfter27Days.collateral);
        console2.log("swapAfter27Days.openTimestamp", swapAfter27Days.openTimestamp);
        console2.log("swapAfter27Days.endTimestamp", swapAfter27Days.endTimestamp);
        console2.log("swapAfter27Days.fixedInterestRate", swapAfter27Days.fixedInterestRate);
        console2.log("swapAfter27Days.ibtQuantity", swapAfter27Days.ibtQuantity);
        console2.log("swapAfter27Days.notional", swapAfter27Days.notional);
        console2.log("swapAfter27Days.direction", swapAfter27Days.direction);
        console2.log("swapAfter27Days.leverage", swapAfter27Days.leverage);
        console2.logInt(swapAfter27Days.payoff);
    }

    function test27D_USDC() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(USDC, user, 500_000e6);

        uint256 balanceUsdcBefore = ERC20(USDC).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(user, 10_000e6, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            USDC,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceUsdcAfter = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcBefore", balanceUsdcBefore);
        console2.log("balanceUsdcAfter", balanceUsdcAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 27 days);

        IporTypes.AccruedIpor memory accruedIporAfter27Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter27Days", accruedIporAfter27Days.indexValue);
        console2.log("ibtPriceAfter27Days", accruedIporAfter27Days.ibtPrice);

        (uint256 totalCountAfter27Days, IAmmSwapsLens.IporSwap[] memory swapsAfter27Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter27Days = swapsAfter27Days[0];
        console2.log("swapAfter27Days.collateral", swapAfter27Days.collateral);
        console2.log("swapAfter27Days.openTimestamp", swapAfter27Days.openTimestamp);
        console2.log("swapAfter27Days.endTimestamp", swapAfter27Days.endTimestamp);
        console2.log("swapAfter27Days.fixedInterestRate", swapAfter27Days.fixedInterestRate);
        console2.log("swapAfter27Days.ibtQuantity", swapAfter27Days.ibtQuantity);
        console2.log("swapAfter27Days.notional", swapAfter27Days.notional);
        console2.log("swapAfter27Days.direction", swapAfter27Days.direction);
        console2.log("swapAfter27Days.leverage", swapAfter27Days.leverage);
        console2.logInt(swapAfter27Days.payoff);
    }

    function test59D_USDC() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(USDC, user, 500_000e6);

        uint256 balanceUsdcBefore = ERC20(USDC).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(user, 10_000e6, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            USDC,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceUsdcAfter = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcBefore", balanceUsdcBefore);
        console2.log("balanceUsdcAfter", balanceUsdcAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 59 days);

        IporTypes.AccruedIpor memory accruedIporAfter59Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter59Days", accruedIporAfter59Days.indexValue);
        console2.log("ibtPriceAfter59Days", accruedIporAfter59Days.ibtPrice);

        (uint256 totalCountAfter59Days, IAmmSwapsLens.IporSwap[] memory swapsAfter59Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter59Days = swapsAfter59Days[0];
        console2.log("swapAfter59Days.collateral", swapAfter59Days.collateral);
        console2.log("swapAfter59Days.openTimestamp", swapAfter59Days.openTimestamp);
        console2.log("swapAfter59Days.endTimestamp", swapAfter59Days.endTimestamp);
        console2.log("swapAfter59Days.fixedInterestRate", swapAfter59Days.fixedInterestRate);
        console2.log("swapAfter59Days.ibtQuantity", swapAfter59Days.ibtQuantity);
        console2.log("swapAfter59Days.notional", swapAfter59Days.notional);
        console2.log("swapAfter59Days.direction", swapAfter59Days.direction);
        console2.log("swapAfter59Days.leverage", swapAfter59Days.leverage);
        console2.logInt(swapAfter59Days.payoff);
    }

    function test89D_USDC() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(USDC, user, 500_000e6);

        uint256 balanceUsdcBefore = ERC20(USDC).balanceOf(user);

        // when
        vm.prank(user);
        IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(user, 10_000e6, 1e18, 10e18);

        (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(
            USDC,
            user,
            0,
            10
        );

        // then
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValue", accruedIpor.indexValue);
        console2.log("ibtPrice", accruedIpor.ibtPrice);

        uint256 balanceUsdcAfter = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcBefore", balanceUsdcBefore);
        console2.log("balanceUsdcAfter", balanceUsdcAfter);
        console2.log("swapCount", totalCount);
        console2.log("swapCount", totalCount);

        IAmmSwapsLens.IporSwap memory swap = swaps[0];
        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.openTimestamp", swap.openTimestamp);
        console2.log("swap.endTimestamp", swap.endTimestamp);
        console2.log("swap.fixedInterestRate", swap.fixedInterestRate);
        console2.log("swap.ibtQuantity", swap.ibtQuantity);
        console2.log("swap.notional", swap.notional);
        console2.log("swap.direction", swap.direction);
        console2.log("swap.leverage", swap.leverage);
        console2.logInt(swap.payoff);

        vm.warp(block.timestamp + 89 days);

        IporTypes.AccruedIpor memory accruedIporAfter89Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter89Days", accruedIporAfter89Days.indexValue);
        console2.log("ibtPriceAfter89Days", accruedIporAfter89Days.ibtPrice);

        (uint256 totalCountAfter89Days, IAmmSwapsLens.IporSwap[] memory swapsAfter89Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter89Days = swapsAfter89Days[0];
        console2.log("swapAfter89Days.collateral", swapAfter89Days.collateral);
        console2.log("swapAfter89Days.openTimestamp", swapAfter89Days.openTimestamp);
        console2.log("swapAfter89Days.endTimestamp", swapAfter89Days.endTimestamp);
        console2.log("swapAfter89Days.fixedInterestRate", swapAfter89Days.fixedInterestRate);
        console2.log("swapAfter89Days.ibtQuantity", swapAfter89Days.ibtQuantity);
        console2.log("swapAfter89Days.notional", swapAfter89Days.notional);
        console2.log("swapAfter89Days.direction", swapAfter89Days.direction);
        console2.log("swapAfter89Days.leverage", swapAfter89Days.leverage);
        console2.logInt(swapAfter89Days.payoff);
    }
}
