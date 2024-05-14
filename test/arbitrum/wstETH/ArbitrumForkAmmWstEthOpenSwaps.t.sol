// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ArbitrumTestForkCommons.sol";

contract ArbitrumForkAmmWstEthOpenSwapsTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }

    function testShouldOpenPositionWstEthForWstETH28daysPayFixed() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            address(wstETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryWstEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115257294091, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionWstETHForWstETHPayFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionWstETHForWstETH60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88926909389542842, swap.collateral, "swap.collateral");
        assertEq(889269093895428420, swap.notional, "swap.notional");
        assertEq(889269093895428420, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115206807651, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionWstETHForWstETHPayFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionWstETHForWstETH90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690108, swap.collateral, "swap.collateral");
        assertEq(888904090846901080, swap.notional, "swap.notional");
        assertEq(888904090846901080, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115159516765, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldNotOpenPositionWstETHForWstETHPayFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionWstETHForWstETH28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694884742705909, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionWstETHForWstETHReceiveFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionWstETHForWstETH60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88926909389542842, swap.collateral, "swap.collateral");
        assertEq(889269093895428420, swap.notional, "swap.notional");
        assertEq(889269093895428420, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694884793192349, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionWstEthForWstEthReceiveFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionWstEthForWstEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(wstETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690108, swap.collateral, "swap.collateral");
        assertEq(888904090846901080, swap.notional, "swap.notional");
        assertEq(888904090846901080, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694884840483235, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
    }

    function testShouldNotOpenPositionWstEthForWstEthReceiveFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1 * 1e17;

        deal(wstETH, user, totalAmount - 1000);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount - 1000,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionWstEthForWstEthPayFixed28DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionWstEthForWstEthPayFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
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
                wstETH,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionWstEthForWstEthPayFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
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
                wstETH,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed28DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        deal(wstETH, user, totalAmount / 2);

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryWstEthErc20BalanceBefore = ERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount / 2,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionWStEthForWstEthReceiveFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
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
                wstETH,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionWstEthForWstEthReceiveFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = 1e17;

        vm.prank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

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
            wstETH,
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
                wstETH,
                0,
                totalAmount
            )
        );
        IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotProvideLiquidityWstEthForWstEthWhenOpenedSwapAndMaxLiquidityPoolBalanceAchieved() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

        uint256 ammTreasuryErc20Balance = IStETH(wstETH).balanceOf(ammTreasuryWstEthProxy);

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
            address(wstETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256 newLpLimit = IporMath.division(ammTreasuryErc20Balance, 1e18) +
            IporMath.division(totalAmount / 2, 1e18);

        /// @dev this limit should still allow to provide liquidity
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(wstETH, uint32(newLpLimit), 0, 0);

        uint userOneWstEthBalanceBefore = IStETH(wstETH).balanceOf(user);
        uint userOneIpwstEthBalanceBefore = IERC20(ipwstETH).balanceOf(user);
        uint ammTreasuryWstEthBalanceBefore = IStETH(wstETH).balanceOf(ammTreasuryWstEthProxy);
        uint exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        uint provideAmount = 1 * 1e18;

        //when
        vm.prank(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).provideLiquidityWstEth(user, provideAmount);

        //then
        uint userOneWstEthBalanceAfter = IStETH(wstETH).balanceOf(user);
        uint userOneIpwstEthBalanceAfter = IERC20(ipwstETH).balanceOf(user);
        uint ammTreasuryWstEthBalanceAfter = IStETH(wstETH).balanceOf(ammTreasuryWstEthProxy);
        uint exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertEq(
            userOneWstEthBalanceBefore - provideAmount,
            userOneWstEthBalanceAfter,
            "user balance of stEth should decrease"
        );
        assertLt(userOneIpwstEthBalanceBefore, userOneIpwstEthBalanceAfter, "user balance of ipwstEth should increase");

        assertEq(
            ammTreasuryWstEthBalanceBefore,
            ammTreasuryWstEthBalanceAfter - provideAmount,
            "amm treasury balance"
        );

        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }
}
