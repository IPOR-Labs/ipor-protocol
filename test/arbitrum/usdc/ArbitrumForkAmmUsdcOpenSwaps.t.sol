// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IAmmOpenSwapServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmOpenSwapServiceUsdc.sol";

import "./UsdcTestForkCommonArbitrum.sol";
import {IWETH9} from "../../../contracts/amm-eth/interfaces/IWETH9.sol";
contract ArbitrumForkAmmUsdcOpenSwapsTest is UsdcTestForkCommonArbitrum {

    uint256 public constant T_ASSET_DECIMALS = 1e6;

    function testShouldOpenPositionUSDCForUSDC28daysPayFixed() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1 * 1e5;

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
            address(USDC),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryUsdcErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018534722386, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionUsdcForUsdc60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1 * 1e5;

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88926909389542842, swap.collateral, "swap.collateral");
        assertEq(889269093895428420, swap.notional, "swap.notional");
        assertEq(889269093895428420, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018526604140, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionUsdcForUsdc90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1 * 1e5;

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690108, swap.collateral, "swap.collateral");
        assertEq(888904090846901080, swap.notional, "swap.notional");
        assertEq(888904090846901080, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000018518999741, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionUsdcForUsdc28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1 * 1e5;

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694981465277614, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionUsdcForUsdcReceiveFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionUsdcForUsdc60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1e5;

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88926909389542842, swap.collateral, "swap.collateral");
        assertEq(889269093895428420, swap.notional, "swap.notional");
        assertEq(889269093895428420, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694981473395860, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionUsdcForUsdcReceiveFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionUsdcForUsdc90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1e5;

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(USDC, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690108, swap.collateral, "swap.collateral");
        assertEq(888904090846901080, swap.notional, "swap.notional");
        assertEq(888904090846901080, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694981481000259, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionUsdcForUsdcReceiveFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e5;

        deal(USDC, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed28DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e5;

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        uint256 ammTreasuryUsdcErc20BalanceBefore = ERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e5;

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionUsdcForUsdcPayFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e5;

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }


    function testShouldNotOpenPositionUsdcForUsdcReceiveFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e5;

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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
            1,
            messageSignerPrivateKey
        );

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed60daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionUsdcForUsdcReceiveFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e5;

        vm.prank(user);
        IWETH9(USDC).approve(iporProtocolRouterProxy, type(uint256).max);

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
            1,
            messageSignerPrivateKey
        );

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                USDC,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapReceiveFixed90daysUsdc(
            user,
            USDC,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

}
