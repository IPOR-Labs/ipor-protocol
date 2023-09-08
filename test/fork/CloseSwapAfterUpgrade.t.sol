// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/types/AmmTypes.sol";
import "./TestForkCommons.sol";
import "./IAsset.sol";

interface IMilton {
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);
}

interface IMiltonStorage {
    struct IporSwapMemory {
        uint256 id;
        address buyer;
        uint256 openTimestamp;
        uint256 endTimestamp;
        uint256 idsIndex;
        uint256 collateral;
        uint256 notional;
        uint256 ibtQuantity;
        uint256 fixedInterestRate;
        uint256 liquidationDepositAmount;
        uint256 state;
    }

    function getSwapPayFixed(uint256 swapId) external view returns (IporSwapMemory memory);

    function getSwapReceiveFixed(uint256 swapId) external view returns (IporSwapMemory memory);
}

contract CloseSwapAfterUpgradeTest is TestForkCommons {
    using SafeERC20 for ERC20;

    function setUp() public {
        /// @dev blockchain state: with DSR before upgrade to v2
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18070000);
    }

    function testShouldCloseSwapTenor28DaiPayFixed() public {
        //given
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(miltonProxyDai, type(uint256).max);

        deal(DAI, user, 500_000e18);

        vm.prank(user);
        uint256 swapId = IMilton(miltonProxyDai).openSwapPayFixed(2_000 * 1e18, 9e18, 10e18);

        IMiltonStorage.IporSwapMemory memory swapBeforeUpgrade = IMiltonStorage(miltonStorageProxyDai).getSwapPayFixed(
            swapId
        );

        vm.warp(block.timestamp + 5 days);

        //when
        _init();

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swapAfterUpgradeBeforeClose = swaps[0];

        AmmTypes.Swap memory swapAfterUpgradeBeforeCloseStorage = IAmmStorage(miltonStorageProxyDai).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        /// @dev checking swap via Router
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeClose.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeClose.buyer, "swap.buyer");
        assertEq(swapBeforeUpgrade.openTimestamp, swapAfterUpgradeBeforeClose.openTimestamp, "swap.openTimestamp");
        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeClose.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeClose.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeClose.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeClose.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeClose.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, swapAfterUpgradeBeforeClose.state, "swap.state");

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeBeforeCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeBeforeCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, uint256(swapAfterUpgradeBeforeCloseStorage.state), "swap.state");

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(user, swapPfIds, swapRfIds);

        AmmTypes.Swap memory swapAfterUpgradeAfterCloseStorage = AmmStorage(miltonStorageProxyDai).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeAfterCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeAfterCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeAfterCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeAfterCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeAfterCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeAfterCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeAfterCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeAfterCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeAfterCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(0, uint256(swapAfterUpgradeAfterCloseStorage.state), "swap.state");
    }

    function testShouldCloseSwapTenor28DaiReceiveFixed() public {
        //given
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(miltonProxyDai, type(uint256).max);

        deal(DAI, user, 500_000e18);

        vm.prank(user);
        uint256 swapId = IMilton(miltonProxyDai).openSwapReceiveFixed(1000e18, 0, 100e18);

        IMiltonStorage.IporSwapMemory memory swapBeforeUpgrade = IMiltonStorage(miltonStorageProxyDai)
            .getSwapReceiveFixed(swapId);

        vm.warp(block.timestamp + 5 days);

        //when
        _init();

        //then
        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swapAfterUpgradeBeforeClose = swaps[0];

        AmmTypes.Swap memory swapAfterUpgradeBeforeCloseStorage = IAmmStorage(miltonStorageProxyDai).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        /// @dev checking swap via Router
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeClose.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeClose.buyer, "swap.buyer");
        assertEq(swapBeforeUpgrade.openTimestamp, swapAfterUpgradeBeforeClose.openTimestamp, "swap.openTimestamp");
        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeClose.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeClose.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeClose.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeClose.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeClose.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, swapAfterUpgradeBeforeClose.state, "swap.state");

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeBeforeCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeBeforeCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, uint256(swapAfterUpgradeBeforeCloseStorage.state), "swap.state");

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(user, swapPfIds, swapRfIds);

        AmmTypes.Swap memory swapAfterUpgradeAfterCloseStorage = AmmStorage(miltonStorageProxyDai).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeAfterCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeAfterCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeAfterCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeAfterCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeAfterCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeAfterCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeAfterCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeAfterCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeAfterCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(0, uint256(swapAfterUpgradeAfterCloseStorage.state), "swap.state");
    }

    function testShouldCloseSwapTenor28UsdcPayFixed() public {
        //given
        address user = _getUserAddress(22);

        vm.startPrank(user);
        ERC20(USDC).safeApprove(miltonProxyUsdc, 500_000e6);
        vm.stopPrank();

        deal(USDC, user, 500_000e6);

        vm.prank(user);
        uint256 swapId = IMilton(miltonProxyUsdc).openSwapPayFixed(2_000 * 1e6, 9e18, 10e18);

        IMiltonStorage.IporSwapMemory memory swapBeforeUpgrade = IMiltonStorage(miltonStorageProxyUsdc).getSwapPayFixed(
            swapId
        );

        vm.warp(block.timestamp + 5 days);

        //when
        _init();

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swapAfterUpgradeBeforeClose = swaps[0];

        AmmTypes.Swap memory swapAfterUpgradeBeforeCloseStorage = IAmmStorage(miltonStorageProxyUsdc).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        /// @dev checking swap via Router
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeClose.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeClose.buyer, "swap.buyer");
        assertEq(swapBeforeUpgrade.openTimestamp, swapAfterUpgradeBeforeClose.openTimestamp, "swap.openTimestamp");
        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeClose.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeClose.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeClose.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeClose.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeClose.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, swapAfterUpgradeBeforeClose.state, "swap.state");

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeBeforeCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeBeforeCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, uint256(swapAfterUpgradeBeforeCloseStorage.state), "swap.state");

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsUsdc(user, swapPfIds, swapRfIds);

        AmmTypes.Swap memory swapAfterUpgradeAfterCloseStorage = AmmStorage(miltonStorageProxyUsdc).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeAfterCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeAfterCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeAfterCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeAfterCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeAfterCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeAfterCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeAfterCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeAfterCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeAfterCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(0, uint256(swapAfterUpgradeAfterCloseStorage.state), "swap.state");
    }

    function testShouldCloseSwapTenor28UsdtReceiveFixed() public {
        //given
        address user = _getUserAddress(22);

        vm.startPrank(user);
        ERC20(USDT).safeApprove(miltonProxyUsdt, 500_000e6);
        vm.stopPrank();

        deal(USDT, user, 500_000e6);

        vm.prank(user);
        uint256 swapId = IMilton(miltonProxyUsdt).openSwapReceiveFixed(1000e6, 0, 100e18);

        IMiltonStorage.IporSwapMemory memory swapBeforeUpgrade = IMiltonStorage(miltonStorageProxyUsdt)
            .getSwapReceiveFixed(swapId);

        vm.warp(block.timestamp + 5 days);

        //when
        _init();

        //then
        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDT, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swapAfterUpgradeBeforeClose = swaps[0];

        AmmTypes.Swap memory swapAfterUpgradeBeforeCloseStorage = IAmmStorage(miltonStorageProxyUsdt).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        /// @dev checking swap via Router
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeClose.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeClose.buyer, "swap.buyer");
        assertEq(swapBeforeUpgrade.openTimestamp, swapAfterUpgradeBeforeClose.openTimestamp, "swap.openTimestamp");
        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeClose.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeClose.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeClose.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeClose.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeClose.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, swapAfterUpgradeBeforeClose.state, "swap.state");

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeBeforeCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeBeforeCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeBeforeCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeBeforeCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(swapBeforeUpgrade.state, uint256(swapAfterUpgradeBeforeCloseStorage.state), "swap.state");

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsUsdt(user, swapPfIds, swapRfIds);

        AmmTypes.Swap memory swapAfterUpgradeAfterCloseStorage = AmmStorage(miltonStorageProxyUsdt).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        /// @dev checking swap via AmmStorage
        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeAfterCloseStorage.id, "swapId");
        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeAfterCloseStorage.buyer, "swap.buyer");
        assertEq(
            swapBeforeUpgrade.openTimestamp,
            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
            "swap.openTimestamp"
        );

        assertEq(uint256(swapAfterUpgradeAfterCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeAfterCloseStorage.idsIndex, "swap.idsIndex");

        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeAfterCloseStorage.collateral, "swap.collateral");
        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeAfterCloseStorage.notional, "swap.notional");
        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeAfterCloseStorage.ibtQuantity, "swap.ibtQuantity");
        assertEq(
            swapBeforeUpgrade.fixedInterestRate,
            swapAfterUpgradeAfterCloseStorage.fixedInterestRate,
            "swap.fixedInterestRate"
        );
        assertEq(
            swapBeforeUpgrade.liquidationDepositAmount,
            swapAfterUpgradeAfterCloseStorage.liquidationDepositAmount,
            "swap.liquidationDepositAmount"
        );
        assertEq(0, uint256(swapAfterUpgradeAfterCloseStorage.state), "swap.state");
    }

    function testShouldCloseInV2SwapFromV1AndNotUpdateTimeWeightedTenor28DaiPayFixed() public {
        //given
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(miltonProxyDai, type(uint256).max);

        deal(DAI, user, 500_000e18);

        vm.prank(user);
        uint256 swapIdV1 = IMilton(miltonProxyDai).openSwapPayFixed(2_000 * 1e18, 9e18, 10e18);

        IMiltonStorage.IporSwapMemory memory swapBeforeUpgrade = IMiltonStorage(miltonStorageProxyDai).getSwapPayFixed(
            swapIdV1
        );

        vm.warp(block.timestamp + 5 days);

        //when
        _init();

        //then
//        vm.prank(user);
//        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
//
//        vm.prank(user);
//        uint256 swapIdV2 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
//            user,
//            2_000 * 1e18,
//            9e18,
//            10e18
//        );

//        IAmmSwapsLens.IporSwap[] memory swaps;
//        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
//        IAmmSwapsLens.IporSwap memory swapAfterUpgradeBeforeClose = swaps[0];
//
//        AmmTypes.Swap memory swapAfterUpgradeBeforeCloseStorage = IAmmStorage(miltonStorageProxyDai).getSwap(
//            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
//            swapIdV1
//        );

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalBeforeClose = SpreadStorageLens(
            spreadRouter
        ).getTimeWeightedNotional();

        console2.log("KEY 0: ", timeWeightedNotionalBeforeClose[0].key);
        console2.log(
            "KEY 0 - timeWeightedNotionalPayFixed: ",
            timeWeightedNotionalBeforeClose[0].timeWeightedNotional.timeWeightedNotionalPayFixed
        );

        //        /// @dev checking swap via Router
        //        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeClose.id, "swapId");
        //        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeClose.buyer, "swap.buyer");
        //        assertEq(swapBeforeUpgrade.openTimestamp, swapAfterUpgradeBeforeClose.openTimestamp, "swap.openTimestamp");
        //        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeClose.collateral, "swap.collateral");
        //        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeClose.notional, "swap.notional");
        //        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeClose.ibtQuantity, "swap.ibtQuantity");
        //        assertEq(
        //            swapBeforeUpgrade.fixedInterestRate,
        //            swapAfterUpgradeBeforeClose.fixedInterestRate,
        //            "swap.fixedInterestRate"
        //        );
        //        assertEq(
        //            swapBeforeUpgrade.liquidationDepositAmount,
        //            swapAfterUpgradeBeforeClose.liquidationDepositAmount,
        //            "swap.liquidationDepositAmount"
        //        );
        //        assertEq(swapBeforeUpgrade.state, swapAfterUpgradeBeforeClose.state, "swap.state");
        //
        //        /// @dev checking swap via AmmStorage
        //        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeBeforeCloseStorage.id, "swapId");
        //        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeBeforeCloseStorage.buyer, "swap.buyer");
        //        assertEq(
        //            swapBeforeUpgrade.openTimestamp,
        //            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
        //            "swap.openTimestamp"
        //        );
        //
        //        assertEq(uint256(swapAfterUpgradeBeforeCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        //        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeBeforeCloseStorage.idsIndex, "swap.idsIndex");
        //
        //        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeBeforeCloseStorage.collateral, "swap.collateral");
        //        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeBeforeCloseStorage.notional, "swap.notional");
        //        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeBeforeCloseStorage.ibtQuantity, "swap.ibtQuantity");
        //        assertEq(
        //            swapBeforeUpgrade.fixedInterestRate,
        //            swapAfterUpgradeBeforeCloseStorage.fixedInterestRate,
        //            "swap.fixedInterestRate"
        //        );
        //        assertEq(
        //            swapBeforeUpgrade.liquidationDepositAmount,
        //            swapAfterUpgradeBeforeCloseStorage.liquidationDepositAmount,
        //            "swap.liquidationDepositAmount"
        //        );
        //        assertEq(swapBeforeUpgrade.state, uint256(swapAfterUpgradeBeforeCloseStorage.state), "swap.state");
        //
        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapIdV1;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.prank(user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(user, swapPfIds, swapRfIds);

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalAfterClose = SpreadStorageLens(
            spreadRouter
        ).getTimeWeightedNotional();

        console2.log("AFTER KEY 0: ", timeWeightedNotionalAfterClose[0].key);
        console2.log(
            "AFTER KEY 0 - timeWeightedNotionalPayFixed: ",
            timeWeightedNotionalAfterClose[1].timeWeightedNotional.timeWeightedNotionalPayFixed
        );

        assertEq(timeWeightedNotionalBeforeClose[0].timeWeightedNotional.timeWeightedNotionalPayFixed, 0);
        assertEq(timeWeightedNotionalAfterClose[0].timeWeightedNotional.timeWeightedNotionalPayFixed, 0);

        //        AmmTypes.Swap memory swapAfterUpgradeAfterCloseStorage = AmmStorage(miltonStorageProxyDai).getSwap(
        //            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
        //            swapId
        //        );
        //
        //        /// @dev checking swap via AmmStorage
        //        assertEq(swapBeforeUpgrade.id, swapAfterUpgradeAfterCloseStorage.id, "swapId");
        //        assertEq(swapBeforeUpgrade.buyer, swapAfterUpgradeAfterCloseStorage.buyer, "swap.buyer");
        //        assertEq(
        //            swapBeforeUpgrade.openTimestamp,
        //            swapAfterUpgradeBeforeCloseStorage.openTimestamp,
        //            "swap.openTimestamp"
        //        );
        //
        //        assertEq(uint256(swapAfterUpgradeAfterCloseStorage.tenor), uint256(IporTypes.SwapTenor.DAYS_28), "swap.tenor");
        //        assertEq(swapBeforeUpgrade.idsIndex, swapAfterUpgradeAfterCloseStorage.idsIndex, "swap.idsIndex");
        //
        //        assertEq(swapBeforeUpgrade.collateral, swapAfterUpgradeAfterCloseStorage.collateral, "swap.collateral");
        //        assertEq(swapBeforeUpgrade.notional, swapAfterUpgradeAfterCloseStorage.notional, "swap.notional");
        //        assertEq(swapBeforeUpgrade.ibtQuantity, swapAfterUpgradeAfterCloseStorage.ibtQuantity, "swap.ibtQuantity");
        //        assertEq(
        //            swapBeforeUpgrade.fixedInterestRate,
        //            swapAfterUpgradeAfterCloseStorage.fixedInterestRate,
        //            "swap.fixedInterestRate"
        //        );
        //        assertEq(
        //            swapBeforeUpgrade.liquidationDepositAmount,
        //            swapAfterUpgradeAfterCloseStorage.liquidationDepositAmount,
        //            "swap.liquidationDepositAmount"
        //        );
        //        assertEq(0, uint256(swapAfterUpgradeAfterCloseStorage.state), "swap.state");
    }
}
