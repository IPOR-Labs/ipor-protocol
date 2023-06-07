// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IIpToken.sol";

contract OpenSwapForkTest is TestForkCommons {
    function test28D() public {
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

        vm.warp(block.timestamp + 28 days);

        IporTypes.AccruedIpor memory accruedIporAfter28Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter28Days", accruedIporAfter28Days.indexValue);
        console2.log("ibtPriceAfter28Days", accruedIporAfter28Days.ibtPrice);

        (uint256 totalCountAfter28Days, IAmmSwapsLens.IporSwap[] memory swapsAfter28Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter28Days = swapsAfter28Days[0];
        console2.log("swapAfter28Days.collateral", swapAfter28Days.collateral);
        console2.log("swapAfter28Days.openTimestamp", swapAfter28Days.openTimestamp);
        console2.log("swapAfter28Days.endTimestamp", swapAfter28Days.endTimestamp);
        console2.log("swapAfter28Days.fixedInterestRate", swapAfter28Days.fixedInterestRate);
        console2.log("swapAfter28Days.ibtQuantity", swapAfter28Days.ibtQuantity);
        console2.log("swapAfter28Days.notional", swapAfter28Days.notional);
        console2.log("swapAfter28Days.direction", swapAfter28Days.direction);
        console2.log("swapAfter28Days.leverage", swapAfter28Days.leverage);
        console2.logInt(swapAfter28Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedDai(user, swapAfter28Days.id);

        uint256 balanceDaiAfterCloseSwap = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiAfterCloseSwap", balanceDaiAfterCloseSwap);
    }

    function test60D() public {
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

        vm.warp(block.timestamp + 60 days);

        IporTypes.AccruedIpor memory accruedIporAfter60Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter60Days", accruedIporAfter60Days.indexValue);
        console2.log("ibtPriceAfter60Days", accruedIporAfter60Days.ibtPrice);

        (uint256 totalCountAfter60Days, IAmmSwapsLens.IporSwap[] memory swapsAfter60Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter60Days = swapsAfter60Days[0];
        console2.log("swapAfter60Days.collateral", swapAfter60Days.collateral);
        console2.log("swapAfter60Days.openTimestamp", swapAfter60Days.openTimestamp);
        console2.log("swapAfter60Days.endTimestamp", swapAfter60Days.endTimestamp);
        console2.log("swapAfter60Days.fixedInterestRate", swapAfter60Days.fixedInterestRate);
        console2.log("swapAfter60Days.ibtQuantity", swapAfter60Days.ibtQuantity);
        console2.log("swapAfter60Days.notional", swapAfter60Days.notional);
        console2.log("swapAfter60Days.direction", swapAfter60Days.direction);
        console2.log("swapAfter60Days.leverage", swapAfter60Days.leverage);
        console2.logInt(swapAfter60Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedDai(user, swapAfter60Days.id);

        uint256 balanceDaiAfterCloseSwap = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiAfterCloseSwap", balanceDaiAfterCloseSwap);
    }

    function test90D() public {
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

        vm.warp(block.timestamp + 90 days);

        IporTypes.AccruedIpor memory accruedIporAfter90Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter90Days", accruedIporAfter90Days.indexValue);
        console2.log("ibtPriceAfter90Days", accruedIporAfter90Days.ibtPrice);

        (uint256 totalCountAfter90Days, IAmmSwapsLens.IporSwap[] memory swapsAfter90Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter90Days = swapsAfter90Days[0];
        console2.log("swapAfter90Days.collateral", swapAfter90Days.collateral);
        console2.log("swapAfter90Days.openTimestamp", swapAfter90Days.openTimestamp);
        console2.log("swapAfter90Days.endTimestamp", swapAfter90Days.endTimestamp);
        console2.log("swapAfter90Days.fixedInterestRate", swapAfter90Days.fixedInterestRate);
        console2.log("swapAfter90Days.ibtQuantity", swapAfter90Days.ibtQuantity);
        console2.log("swapAfter90Days.notional", swapAfter90Days.notional);
        console2.log("swapAfter90Days.direction", swapAfter90Days.direction);
        console2.log("swapAfter90Days.leverage", swapAfter90Days.leverage);
        console2.logInt(swapAfter90Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedDai(user, swapAfter90Days.id);

        uint256 balanceDaiAfterCloseSwap = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiAfterCloseSwap", balanceDaiAfterCloseSwap);
    }

    function test28DWithIndexPublication() public {
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

        vm.warp(block.timestamp + 28 days);

        IporTypes.AccruedIpor memory accruedIporAfter28Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        console2.log("indexValueAfter28Days", accruedIporAfter28Days.indexValue);
        console2.log("ibtPriceAfter28Days", accruedIporAfter28Days.ibtPrice);

        (uint256 totalCountAfter28Days, IAmmSwapsLens.IporSwap[] memory swapsAfter28Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(DAI, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter28Days = swapsAfter28Days[0];
        console2.log("swapAfter28Days.collateral", swapAfter28Days.collateral);
        console2.log("swapAfter28Days.openTimestamp", swapAfter28Days.openTimestamp);
        console2.log("swapAfter28Days.endTimestamp", swapAfter28Days.endTimestamp);
        console2.log("swapAfter28Days.fixedInterestRate", swapAfter28Days.fixedInterestRate);
        console2.log("swapAfter28Days.ibtQuantity", swapAfter28Days.ibtQuantity);
        console2.log("swapAfter28Days.notional", swapAfter28Days.notional);
        console2.log("swapAfter28Days.direction", swapAfter28Days.direction);
        console2.log("swapAfter28Days.leverage", swapAfter28Days.leverage);
        console2.logInt(swapAfter28Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedDai(user, swapAfter28Days.id);

        uint256 balanceDaiAfterCloseSwap = ERC20(DAI).balanceOf(user);

        console2.log("balanceDaiAfterCloseSwap", balanceDaiAfterCloseSwap);
    }

    function test28D_USDC() public {
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

        vm.warp(block.timestamp + 28 days);

        IporTypes.AccruedIpor memory accruedIporAfter28Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter28Days", accruedIporAfter28Days.indexValue);
        console2.log("ibtPriceAfter28Days", accruedIporAfter28Days.ibtPrice);

        (uint256 totalCountAfter28Days, IAmmSwapsLens.IporSwap[] memory swapsAfter28Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter28Days = swapsAfter28Days[0];
        console2.log("swapAfter28Days.collateral", swapAfter28Days.collateral);
        console2.log("swapAfter28Days.openTimestamp", swapAfter28Days.openTimestamp);
        console2.log("swapAfter28Days.endTimestamp", swapAfter28Days.endTimestamp);
        console2.log("swapAfter28Days.fixedInterestRate", swapAfter28Days.fixedInterestRate);
        console2.log("swapAfter28Days.ibtQuantity", swapAfter28Days.ibtQuantity);
        console2.log("swapAfter28Days.notional", swapAfter28Days.notional);
        console2.log("swapAfter28Days.direction", swapAfter28Days.direction);
        console2.log("swapAfter28Days.leverage", swapAfter28Days.leverage);
        console2.logInt(swapAfter28Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedUsdc(user, swapAfter28Days.id);

        uint256 balanceUsdcAfterCloseSwap = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcAfterCloseSwap", balanceUsdcAfterCloseSwap);
    }

    function test60D_USDC() public {
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

        vm.warp(block.timestamp + 60 days);

        IporTypes.AccruedIpor memory accruedIporAfter60Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter60Days", accruedIporAfter60Days.indexValue);
        console2.log("ibtPriceAfter60Days", accruedIporAfter60Days.ibtPrice);

        (uint256 totalCountAfter60Days, IAmmSwapsLens.IporSwap[] memory swapsAfter60Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter60Days = swapsAfter60Days[0];
        console2.log("swapAfter60Days.collateral", swapAfter60Days.collateral);
        console2.log("swapAfter60Days.openTimestamp", swapAfter60Days.openTimestamp);
        console2.log("swapAfter60Days.endTimestamp", swapAfter60Days.endTimestamp);
        console2.log("swapAfter60Days.fixedInterestRate", swapAfter60Days.fixedInterestRate);
        console2.log("swapAfter60Days.ibtQuantity", swapAfter60Days.ibtQuantity);
        console2.log("swapAfter60Days.notional", swapAfter60Days.notional);
        console2.log("swapAfter60Days.direction", swapAfter60Days.direction);
        console2.log("swapAfter60Days.leverage", swapAfter60Days.leverage);
        console2.logInt(swapAfter60Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedUsdc(user, swapAfter60Days.id);

        uint256 balanceUsdcAfterCloseSwap = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcAfterCloseSwap", balanceUsdcAfterCloseSwap);
    }

    function test90D_USDC() public {
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

        vm.warp(block.timestamp + 90 days);

        IporTypes.AccruedIpor memory accruedIporAfter90Days = IIporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, USDC);
        console2.log("indexValueAfter90Days", accruedIporAfter90Days.indexValue);
        console2.log("ibtPriceAfter90Days", accruedIporAfter90Days.ibtPrice);

        (uint256 totalCountAfter90Days, IAmmSwapsLens.IporSwap[] memory swapsAfter90Days) = IAmmSwapsLens(
            iporProtocolRouterProxy
        ).getSwaps(USDC, user, 0, 10);

        IAmmSwapsLens.IporSwap memory swapAfter90Days = swapsAfter90Days[0];
        console2.log("swapAfter90Days.collateral", swapAfter90Days.collateral);
        console2.log("swapAfter90Days.openTimestamp", swapAfter90Days.openTimestamp);
        console2.log("swapAfter90Days.endTimestamp", swapAfter90Days.endTimestamp);
        console2.log("swapAfter90Days.fixedInterestRate", swapAfter90Days.fixedInterestRate);
        console2.log("swapAfter90Days.ibtQuantity", swapAfter90Days.ibtQuantity);
        console2.log("swapAfter90Days.notional", swapAfter90Days.notional);
        console2.log("swapAfter90Days.direction", swapAfter90Days.direction);
        console2.log("swapAfter90Days.leverage", swapAfter90Days.leverage);
        console2.logInt(swapAfter90Days.payoff);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapPayFixedUsdc(user, swapAfter90Days.id);

        uint256 balanceUsdcAfterCloseSwap = ERC20(USDC).balanceOf(user);

        console2.log("balanceUsdcAfterCloseSwap", balanceUsdcAfterCloseSwap);
    }
}
