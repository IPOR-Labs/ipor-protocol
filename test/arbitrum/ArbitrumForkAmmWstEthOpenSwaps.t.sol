// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ArbitrumTestForkCommons.sol";

contract ArbitrumForkAmmWstEthOpenSwapsTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 19025601);
    }

    function testShouldOpenPositionStEthForwstEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316919, swap.collateral, "swap.collateral");
        assertEq(889658761023169190, swap.notional, "swap.notional");
        assertEq(889658761023169190, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115257294091, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(
            totalAmount,
            IwstEth(wstETH).getWstETHByStETH(ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore) +
                1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionStEthForwstEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88926909389542841, swap.collateral, "swap.collateral");
        assertEq(889269093895428410, swap.notional, "swap.notional");
        assertEq(889269093895428410, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115206807651, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(
            totalAmount,
            IwstEth(wstETH).getWstETHByStETH(ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore) +
                1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }


    function testShouldOpenPositionStEthForwstEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690107, swap.collateral, "swap.collateral");
        assertEq(888904090846901070, swap.notional, "swap.notional");
        assertEq(888904090846901070, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115159516765, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(
            totalAmount,
            IwstEth(wstETH).getWstETHByStETH(ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore) +
                1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionStEthForwstEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316919, swap.collateral, "swap.collateral");
        assertEq(889658761023169190, swap.notional, "swap.notional");
        assertEq(889658761023169190, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694884742705909, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
        assertEq(
            totalAmount,
            IwstEth(wstETH).getWstETHByStETH(ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore) +
                1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed28DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionStEthForWEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
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
        assertEq(
            totalAmount,
            ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore + 1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed60DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenPositionStEthForStEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            stETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
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
        assertEq(
            totalAmount,
            ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore + 1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldOpenPositionStEthForEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
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
        assertEq(
            totalAmount,
            ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore + 1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldOpenPositionStEthForWEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
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
        assertEq(
            totalAmount,
            ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore + 1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldOpenPositionStEthForwstEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88890409084690107, swap.collateral, "swap.collateral");
        assertEq(888904090846901070, swap.notional, "swap.notional");
        assertEq(888904090846901070, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694884840483235, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(1, swap.direction, "swap.direction");
        assertEq(
            totalAmount,
            IwstEth(wstETH).getWstETHByStETH(ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore) +
                1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed90DaysNotEnoughBalanceCase1() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed28DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //when
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.InputAssetBalanceTooLow.selector,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                wstETH,
                totalAmount / 2,
                87235841251539968
            )
        );
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
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
                totalAmount / 2,
                87235841251539968
            )
        );
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthPayFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
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
                totalAmount / 2,
                totalAmount
            )
        );
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
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

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

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
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed60DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
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
                totalAmount / 2,
                totalAmount
            )
        );
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPositionStEthForwstEthReceiveFixed90DaysNotEnoughBalance() public {
        //given
        _init();
        address user = _getUserAddress(22);

        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1e17);

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
            address(stETH),
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
                totalAmount / 2,
                87235841251539968
            )
        );
        IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }

    function testShouldNotProvideLiquidityStEthForWEthWhenOpenedSwapAndMaxLiquidityPoolBalanceAchieved() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

        uint256 ammTreasuryErc20Balance = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            stETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256 newLpLimit = IporMath.division(ammTreasuryErc20Balance, 1e18) +
            IporMath.division(totalAmount / 2, 1e18);

        /// @dev this limit should still allow to provide liquidity
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(stETH, uint32(newLpLimit), 0, 0);

        uint userWEthBalanceBefore = IWETH9(wETH).balanceOf(user);
        uint userOneIpstEthBalanceBefore = IERC20(ipstETH).balanceOf(user);
        uint ammTreasuryStEthBalanceBefore = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);
        uint exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        uint provideAmount = 1 * 1e18;

        //when
        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityWEth(user, provideAmount);

        //then
        uint userWEthBalanceAfter = IWETH9(wETH).balanceOf(user);
        uint userOneIpstEthBalanceAfter = IERC20(ipstETH).balanceOf(user);
        uint ammTreasuryStEthBalanceAfter = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);
        uint exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(userWEthBalanceBefore - provideAmount, userWEthBalanceAfter, "user balance of wEth should decrease");
        assertLt(userOneIpstEthBalanceBefore, userOneIpstEthBalanceAfter, "user balance of ipstEth should increase");

        assertEq(
            ammTreasuryStEthBalanceBefore,
            ammTreasuryStEthBalanceAfter - provideAmount + 1,
            "amm treasury balance"
        );

        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

}
