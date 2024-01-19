// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";

contract ForkOpenCloseSwap is TestForkCommons {
    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18533218);
    }

    function testShouldOpenSwapTenor28DaiPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            user,
            2_000 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(331, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(1964246590348907269306, swap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, swap.notional, "swap.notional");
        assertEq(19001703562314131674314, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(52421141488040047, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldCloseSwapTenor28DaiPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.warp(block.timestamp);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsPayFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 2 days,
            signature: bytes("0x00")
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsReceiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 2 days,
            signature: bytes("0x00")
        });

        riskIndicatorsInputsPayFixed.signature = signRiskParams(
            riskIndicatorsInputsPayFixed,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            user,
            2_000 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputsPayFixed
        );

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory openSwap = swaps[0];

        uint256[] memory payFixedSwapIds = new uint256[](1);
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        payFixedSwapIds[0] = openSwap.id;

        vm.warp(block.timestamp + 1 days + 1);

        //when
        vm.prank(user);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = IAmmCloseSwapServiceDai(iporProtocolRouterProxy).closeSwapsDai(
                user,
                payFixedSwapIds,
                receiveFixedSwapIds,
                AmmTypes.CloseSwapRiskIndicatorsInput(riskIndicatorsInputsPayFixed, riskIndicatorsInputsReceiveFixed)
            );

        //then
        /// @dev checking swap via Router
        assertEq(331, openSwap.id, "swapId");
        assertEq(user, openSwap.buyer, "swap.buyer");
        assertEq(block.timestamp - 1 days - 1, openSwap.openTimestamp, "swap.openTimestamp");
        assertEq(1964246590348907269306, openSwap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, openSwap.notional, "swap.notional");
        assertEq(19001703562314131674314, openSwap.ibtQuantity, "swap.ibtQuantity");
        assertEq(52421141488040047, openSwap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, openSwap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, openSwap.state, "swap.state");
        assertEq(closedPayFixedSwaps[0].swapId, openSwap.id, "closedPayFixedSwaps[0].swapId");
        assertTrue(closedPayFixedSwaps[0].closed, "closedPayFixedSwaps[0].swapId");
    }

    function testShouldOpenSwapTenor28DaiReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: int256(-6926000000000000),
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            user,
            2_000 * 1e18,
            1e16,
            10e18,
            riskIndicatorsInputs
        );

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(331, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(1964246590348907269306, swap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, swap.notional, "swap.notional");
        assertEq(19001703562314131674314, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(19195397630443031, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldRevertOpenSwapTenor28DaiReceiveFixedWhenWrongDirectionInParams() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: int256(-6926000000000000),
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.RISK_INDICATORS_SIGNATURE_INVALID));
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            user,
            2_000 * 1e18,
            1e16,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldRevertOpenSwapTenor28DaiReceiveFixedWhenWrongAssetInParams() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: int256(-6926000000000000),
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(USDC),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.RISK_INDICATORS_SIGNATURE_INVALID));
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            user,
            2_000 * 1e18,
            1e16,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldRevertOpenSwapTenor28DaiReceiveFixedWhenWrongBaseSpreadPerLegInParams() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: int256(-6926000000000000),
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );
        riskIndicatorsInputs.baseSpreadPerLeg = int256(-6926000000000001);

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.RISK_INDICATORS_SIGNATURE_INVALID));
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            user,
            2_000 * 1e18,
            1e16,
            10e18,
            riskIndicatorsInputs
        );
    }
}
