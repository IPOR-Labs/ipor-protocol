// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthCloseSwapsTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldClosePositionStEthForStEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            stETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            wETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            wstETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }


    //
    //    function testShouldOpenPositionStEthForStEth60daysPayFixed() public {
    //    }
    //    function testShouldOpenPositionStEthForStEth90daysPayFixed() public {
    //    }
    //
    //    function testShouldOpenPositionStEthForStEth28daysReceiveFixed() public {
    //    }
    //    function testShouldOpenPositionStEthForStEth60daysReceiveFixed() public {
    //    }
    //    function testShouldOpenPositionStEthForStEth90daysReceiveFixed() public {
    //    }
    //
    //    function testShouldNotOpenPositionStEthForStEthNotEnoughBalance() public {
    //    }
    //    function testShouldNotOpenPositionStEthForWEthNotEnoughBalance() public {
    //    }
    //    function testShouldNotOpenPositionStEthForEthNotEnoughBalance() public {
    //    }
    //    function testShouldNotOpenPositionStEthForwstEthNotEnoughBalance() public {
    //    }
    //
    //    function testShouldOpenPositionStEthForStEthAndTransferCorrectLiquidationDepositAmount() public {
    //    }
    //    function testShouldOpenPositionStEthForEthAndTransferCorrectLiquidationDepositAmount() public {
    //    }
    //    function testShouldOpenPositionStEthForWEthAndTransferCorrectLiquidationDepositAmount() public {
    //    }
    //    function testShouldOpenPositionStEthForwstEthAndTransferCorrectLiquidationDepositAmount() public {
    //    }
    //
    //
    //    function testShouldOpenPositionStEthForWETH() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        //when
    //        vm.prank(user);
    //
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
    //            wETH,
    //            user,
    //            1 * 1e17,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //
    //        //then
    //        IAmmSwapsLens.IporSwap[] memory swaps;
    //        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
    //        IAmmSwapsLens.IporSwap memory swap = swaps[0];
    //
    //        /// @dev checking swap via Router
    //        assertEq(1, swap.id, "swapId");
    //        assertEq(user, swap.buyer, "swap.buyer");
    //        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
    //        assertEq(89965492687736186, swap.collateral, "swap.collateral");
    //        assertEq(899654926877361860, swap.notional, "swap.notional");
    //        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
    //        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
    //        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
    //        assertEq(1, swap.state, "swap.state");
    //    }
    //
    //    function testShouldOpenPositionStEthForETH() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        deal(user, 1_000_000e18);
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        //when
    //        vm.prank(user);
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{value: 1 * 1e17}(
    //            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
    //            user,
    //            1 * 1e17,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //
    //        //then
    //        IAmmSwapsLens.IporSwap[] memory swaps;
    //        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
    //        IAmmSwapsLens.IporSwap memory swap = swaps[0];
    //
    //        /// @dev checking swap via Router
    //        assertEq(1, swap.id, "swapId");
    //        assertEq(user, swap.buyer, "swap.buyer");
    //        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
    //        assertEq(89965492687736186, swap.collateral, "swap.collateral");
    //        assertEq(899654926877361860, swap.notional, "swap.notional");
    //        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
    //        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
    //        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
    //        assertEq(1, swap.state, "swap.state");
    //    }
    //
    //
    //    function testShouldOpenPositionStEthFor_wstEth() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        //when
    //        vm.prank(user);
    //
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
    //            wstETH,
    //            user,
    //            1 * 1e17,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //
    //        //then
    //        IAmmSwapsLens.IporSwap[] memory swaps;
    //        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
    //        IAmmSwapsLens.IporSwap memory swap = swaps[0];
    //
    //        /// @dev checking swap via Router
    //        assertEq(1, swap.id, "swapId");
    //        assertEq(user, swap.buyer, "swap.buyer");
    //        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
    //        assertEq(89965492687736186, swap.collateral, "swap.collateral");
    //        assertEq(899654926877361860, swap.notional, "swap.notional");
    //        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
    //        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
    //        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
    //        assertEq(1, swap.state, "swap.state");
    //    }
    //
    //    function testShouldTransferCorrectLiquidationDepositAmountAfterClose() public {}
    //
    //    function testAmmSwapsLensGetSwapsLiquiditaionDepositAmountIsCorrect() public {}
}
