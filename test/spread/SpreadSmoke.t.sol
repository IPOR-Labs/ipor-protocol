// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "./SpreadTestSystem.sol";

contract SpreadSmokeTest is TestCommons {
    SpreadTestSystem internal _spreadTestSystem;
    address internal _ammAddress;
    address internal _routerAddress;
    address internal _owner;
    address dai;
    IporTypes.SpreadInputs internal spreadInputsPayFixed;
    IporTypes.SpreadInputs internal spreadInputsReceiveFixed;

    function setUp() external {
        _ammAddress = _getUserAddress(10);
        _spreadTestSystem = new SpreadTestSystem(_ammAddress);
        _routerAddress = address(_spreadTestSystem.router());
        _owner = _spreadTestSystem.owner();
        dai = address(_spreadTestSystem.dai());
        spreadInputsPayFixed = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 0,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 1e15
        });
        spreadInputsReceiveFixed = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 0,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 5e16
        });
    }

    function testShouldGetZeroSpreadValue() external {
        // given

        // then
        uint256 payFixed28 = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28 = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60 = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60 = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90 = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90 = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28, 1e16, "payFixed28 should be 1e16");
        assertEq(receiveFixed28, 1e16, "receiveFixed28 should be 1e16");

        assertEq(payFixed60, 1e16, "payFixed60 should be 1e16");
        assertEq(receiveFixed60, 1e16, "receiveFixed60 should be 1e16");

        assertEq(payFixed90, 1e16, "payFixed90 should be 1e16");
        assertEq(receiveFixed90, 1e16, "receiveFixed90 should be 1e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 1e15
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateQuotePayFixed28Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(payFixed28Open > 1e16, "payFixed28Open should be greater than 1e16");
        assertTrue(payFixed28After > 1e16, "payFixed28After should be greater than 1e16");
        assertTrue(receiveFixed28After == 1e16, "receiveFixed28After should be equal than 1e16");

        assertTrue(payFixed60After > 1e16, "payFixed60After should be greater than 1e16");
        assertTrue(receiveFixed60After == 1e16, "receiveFixed60After should be equal than 1e16");

        assertTrue(payFixed90After > 1e16, "payFixed90After should be greater than 1e16");
        assertTrue(receiveFixed90After == 1e16, "receiveFixed90After should be equal than 1e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn60PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 1e15
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed60Open = ISpread60Days(_routerAddress).calculateQuotePayFixed60Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(payFixed60Open > 1e16, "payFixed28Open should be greater than 1e16");
        assertTrue(payFixed28After > 1e16, "payFixed28After should be greater than 1e16");
        assertTrue(receiveFixed28After == 1e16, "receiveFixed28After should be equal than 1e16");

        assertTrue(payFixed60After > 1e16, "payFixed60After should be greater than 1e16");
        assertTrue(receiveFixed60After == 1e16, "receiveFixed60After should be equal than 1e16");

        assertTrue(payFixed90After > 1e16, "payFixed90After should be greater than 1e16");
        assertTrue(receiveFixed90After == 1e16, "receiveFixed90After should be equal than 1e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn90PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 1e15
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed90Open = ISpread90Days(_routerAddress).calculateQuotePayFixed90Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(payFixed90Open > 1e16, "payFixed28Open should be greater than 1e16");
        assertTrue(payFixed28After > 1e16, "payFixed28After should be greater than 1e16");
        assertTrue(receiveFixed28After == 1e16, "receiveFixed28After should be equal than 1e16");

        assertTrue(payFixed60After > 1e16, "payFixed60After should be greater than 1e16");
        assertTrue(receiveFixed60After == 1e16, "receiveFixed60After should be equal than 1e16");

        assertTrue(payFixed90After > 1e16, "payFixed90After should be greater than 1e16");
        assertTrue(receiveFixed90After == 1e16, "receiveFixed90After should be equal than 1e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed2() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 1e15
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateQuotePayFixed28Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(payFixed28Open > 1e16, "payFixed28Open should be greater than 1e16");
        assertTrue(payFixed28After > 1e16, "payFixed28After should be greater than 1e16");
        assertTrue(receiveFixed28After == 1e16, "receiveFixed28After should be equal than 1e16");

        assertTrue(payFixed60After > 1e16, "payFixed60After should be greater than 1e16");
        assertTrue(receiveFixed60After == 1e16, "receiveFixed60After should be equal than 1e16");

        assertTrue(payFixed90After > 1e16, "payFixed90After should be greater than 1e16");
        assertTrue(receiveFixed90After == 1e16, "receiveFixed90After should be equal than 1e16");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn28ReceiveFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 5e16
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed28Open = ISpread28Days(_routerAddress).calculateQuoteReceiveFixed28Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(receiveFixed28Open < 1e16, "receiveFixed28Open should be less than 1e16");
        assertTrue(receiveFixed28After < 1e16, "receiveFixed28After should be less than 1e16");
        assertTrue(payFixed28After == 1e16, "payFixed28After should be equal than 1e16");

        assertTrue(receiveFixed60After < 1e16, "receiveFixed60After should be less than 1e16");
        assertTrue(payFixed60After == 1e16, "payFixed60After should be equal than 1e16");

        assertTrue(receiveFixed90After < 1e16, "receiveFixed90After should be less than 1e16");
        assertTrue(payFixed90After == 1e16, "payFixed90After should be equal than 1e16");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn60ReceiveFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 5e16 //todo
        });


        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(spreadInputsReceiveFixed);

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(spreadInputsReceiveFixed);

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(spreadInputsReceiveFixed);

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed60Open = ISpread60Days(_routerAddress).calculateQuoteReceiveFixed60Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(spreadInputsReceiveFixed);

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(spreadInputsReceiveFixed);

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(spreadInputsReceiveFixed);

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(receiveFixed60Open < 1e16, "receiveFixed60Open should be less than 1e16");
        assertTrue(receiveFixed28After < 1e16, "receiveFixed28After should be less than 1e16");
        assertTrue(payFixed28After == 1e16, "payFixed28After should be equal than 1e16");

        assertTrue(receiveFixed60After < 1e16, "receiveFixed60After should be less than 1e16");
        assertTrue(payFixed60After == 1e16, "payFixed60After should be equal than 1e16");

        assertTrue(receiveFixed90After < 1e16, "receiveFixed90After should be less than 1e16");
        assertTrue(payFixed90After == 1e16, "payFixed90After should be equal than 1e16");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn90ReceiveFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpUtilizationPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 5e16
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(spreadInputsReceiveFixed);

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(spreadInputsReceiveFixed);

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(spreadInputsReceiveFixed);

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed90Open = ISpread90Days(_routerAddress).calculateQuoteReceiveFixed90Days(spreadInputsOpen);

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateReceiveFixed28Days(spreadInputsReceiveFixed);

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateReceiveFixed60Days(spreadInputsReceiveFixed);

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateReceiveFixed90Days(spreadInputsReceiveFixed);

        assertEq(payFixed28Before, 1e16, "payFixed28Before should be 1e16");
        assertEq(receiveFixed28Before, 1e16, "receiveFixed28Before should be 1e16");

        assertEq(payFixed60Before, 1e16, "payFixed60Before should be 1e16");
        assertEq(receiveFixed60Before, 1e16, "receiveFixed60Before should be 1e16");

        assertEq(payFixed90Before, 1e16, "payFixed90Before should be 1e16");
        assertEq(receiveFixed90Before, 1e16, "receiveFixed90Before should be 1e16");

        assertTrue(receiveFixed90Open < 1e16, "receiveFixed90Open should be less than 1e16");
        assertTrue(receiveFixed28After < 1e16, "receiveFixed28After should be less than 1e16");
        assertTrue(payFixed28After == 1e16, "payFixed28After should be equal than 1e16");

        assertTrue(receiveFixed60After < 1e16, "receiveFixed60After should be less than 1e16");
        assertTrue(payFixed60After == 1e16, "payFixed60After should be equal than 1e16");

        assertTrue(receiveFixed90After < 1e16, "receiveFixed90After should be less than 1e16");
        assertTrue(payFixed90After == 1e16, "payFixed90After should be equal than 1e16");
    }
}
