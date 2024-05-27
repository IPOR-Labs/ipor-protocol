// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./UsdcTestForkCommonArbitrum.sol";
import {IAmmCloseSwapServiceUsdc} from "../../../contracts/interfaces/IAmmCloseSwapServiceUsdc.sol";
import {IAmmOpenSwapServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmOpenSwapServiceUsdc.sol";

import "../../../contracts/interfaces/types/AmmTypes.sol";

contract ArbitrumForkAmmUsdcCloseSwapsTest is UsdcTestForkCommonArbitrum {
    uint256 public constant T_ASSET_DECIMALS = 1e6;


    function testShouldClosePositionAndWithdrawFromAmmVault() public {
        //TODO:
    }

    function testShouldClosePositionUsdcForUsdc28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 1 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceUsdc(iporProtocolRouterProxy).closeSwapsUsdc(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageUsdcProxy).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018534722386, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionUsdcForUsdc28daysPayFixedBeforeMaturityWithoutUnwind() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 27 days + 1 hours);
        uint256 closeTimestamp = block.timestamp;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        AmmTypes.ClosingSwapDetails memory closingSwapDetails = IAmmCloseSwapLens(iporProtocolRouterProxy)
            .getClosingSwapDetails(
                USDC,
                user,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId,
                closeTimestamp,
                closeRiskIndicatorsInputs
            );

        //then
        assertEq(uint256(closingSwapDetails.closableStatus), uint256(AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE));
        assertEq(closingSwapDetails.swapUnwindRequired, false);
    }

    function testShouldClosePositionUsdcForUsdc60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 2 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceUsdc(iporProtocolRouterProxy).closeSwapsUsdc(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageUsdcProxy).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(88926909389542842, swap.collateral, "swap.collateral");
        assertEq(889269093895428420, swap.notional, "swap.notional");
        assertEq(889269093895428420, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018526604140, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionUsdcForUsdc60daysPayFixedBeforeMaturityWithoutUnwind() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 58 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        uint256 closeTimestamp = block.timestamp;

        //when
        vm.prank(user);
        AmmTypes.ClosingSwapDetails memory closingSwapDetails = IAmmCloseSwapLens(iporProtocolRouterProxy)
            .getClosingSwapDetails(
                USDC,
                user,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId,
                closeTimestamp,
                closeRiskIndicatorsInputs
            );

        //then
        assertEq(uint256(closingSwapDetails.closableStatus), uint256(AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE));
        assertEq(closingSwapDetails.swapUnwindRequired, false);
    }

    function testShouldClosePositionUsdcForUsdc60daysPayFixedBeforeMaturityWITHUnwind() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 57 days + 20 hours);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        uint256 closeTimestamp = block.timestamp;

        //when
        vm.prank(user);
        AmmTypes.ClosingSwapDetails memory closingSwapDetails = IAmmCloseSwapLens(iporProtocolRouterProxy)
            .getClosingSwapDetails(
                USDC,
                user,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId,
                closeTimestamp,
                closeRiskIndicatorsInputs
            );

        //then
        assertEq(uint256(closingSwapDetails.closableStatus), uint256(AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE));
        assertEq(closingSwapDetails.swapUnwindRequired, true);
    }

    function testShouldClosePositionUsdcForUsdc90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 3 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceUsdc(iporProtocolRouterProxy).closeSwapsUsdc(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageUsdcProxy).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(88890409084690108, swap.collateral, "swap.collateral");
        assertEq(888904090846901080, swap.notional, "swap.notional");
        assertEq(888904090846901080, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018518999741, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }


   
}
