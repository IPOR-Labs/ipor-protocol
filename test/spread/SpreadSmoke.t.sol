// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });
        spreadInputsReceiveFixed = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 0,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000
        });
    }

    function testShouldGetZeroSpreadValue() external {
        // given

        // then
        uint256 payFixed28 = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(spreadInputsPayFixed);
        uint256 receiveFixed28 = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60 = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(spreadInputsPayFixed);
        uint256 receiveFixed60 = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90 = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(spreadInputsPayFixed);
        uint256 receiveFixed90 = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        assertEq(payFixed28, 1e16, "payFixed28 should be 1e16");
        assertEq(receiveFixed28, 1e16, "receiveFixed28 should be 1e16");

        assertEq(payFixed60, 1e16, "payFixed60 should be 1e16");
        assertEq(receiveFixed60, 1e16, "receiveFixed60 should be 1e16");

        assertEq(payFixed90, 1e16, "payFixed90 should be 1e16");
        assertEq(receiveFixed90, 1e16, "receiveFixed90 should be 1e16");
    }

    function testShouldChangeOfferRateWhenDemandSpreadFactorChanged() external {
        // given
        spreadInputsPayFixed.swapNotional = 1_000e18;
        spreadInputsReceiveFixed.swapNotional = 1_000e18;

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.demandSpreadFactor = 500;
        spreadInputsReceiveFixed.demandSpreadFactor = 500;

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        // then
        assertTrue(payFixed28Before < payFixed28After, "payFixed28Before should be smaller than payFixed28After");
        assertTrue(
            receiveFixed28Before > receiveFixed28After,
            "receiveFixed28Before should be getter than receiveFixed28After"
        );
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
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

    function testShouldUseCapWhenOneSwapOpenOn28PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000
        });

        // when
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(
            spreadInputsOpen
        );

        // then
        assertTrue(payFixed28Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn60PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed60Open = ISpread60Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed60Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
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

    function testShouldUseCapWhenOneSwapOpenOn60PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000
        });

        // when
        vm.prank(_ammAddress);
        uint256 payFixed60Open = ISpread60Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed60Days(
            spreadInputsOpen
        );

        // then
        assertTrue(payFixed60Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn90PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed90Open = ISpread90Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed90Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
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

    function testUseCapWhenOneSwapOpenOn90PayFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000
        });

        // when
        vm.prank(_ammAddress);
        uint256 payFixed90Open = ISpread90Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed90Days(
            spreadInputsOpen
        );

        // then
        assertTrue(payFixed90Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed2() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
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
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
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

    function testShouldUseCapWhenOneSwapOpenOn28ReceiveFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });
        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(
            spreadInputsOpen
        );

        // then
        assertTrue(receiveFixed28Open < 1e15, "receiveFixed28Open should be less than 1e15");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn60ReceiveFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16, //todo
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed60Open = ISpread60Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed60Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

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

    function testShouldUseCapWhenOneSwapOpenOn60ReceiveFixed() external {
        // given
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15, //todo
            demandSpreadFactor: 1000
        });

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed60Open = ISpread60Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed60Days(
            spreadInputsOpen
        );

        // then
        assertTrue(receiveFixed60Open < 1e15, "receiveFixed60Open should be less than 1e15");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn90ReceiveFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000
        });

        uint256 payFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28Before = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60Before = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90Before = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed90Open = ISpread90Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed90Days(
            spreadInputsOpen
        );

        // then
        uint256 payFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRatePayFixed28Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed28After = ISpread28DaysLens(_routerAddress).calculateOfferedRateReceiveFixed28Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRatePayFixed60Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed60After = ISpread60DaysLens(_routerAddress).calculateOfferedRateReceiveFixed60Days(
            spreadInputsReceiveFixed
        );

        uint256 payFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRatePayFixed90Days(
            spreadInputsPayFixed
        );
        uint256 receiveFixed90After = ISpread90DaysLens(_routerAddress).calculateOfferedRateReceiveFixed90Days(
            spreadInputsReceiveFixed
        );

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

    function testShouldUseCapWhenOneSwapOpenOn90ReceiveFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000
        });

        // when
        vm.prank(_ammAddress);
        uint256 receiveFixed90Open = ISpread90Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed90Days(
            spreadInputsOpen
        );

        // then
        assertTrue(receiveFixed90Open < 1e15, "receiveFixed90Open should be less than 1e15");
    }

    function testShouldBeAbleToOverrideTimeWeightedNotional() external {
        // given
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();
        SpreadTypes.TimeWeightedNotionalMemory[]
            memory timeWeightedNotional = new SpreadTypes.TimeWeightedNotionalMemory[](
                timeWeightedNotionalResponse.length
            );

        for (uint i; i < timeWeightedNotionalResponse.length; i++) {
            timeWeightedNotional[i] = SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .timeWeightedNotionalPayFixed + 100e18,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .timeWeightedNotionalReceiveFixed + 200e18,
                lastUpdateTimePayFixed: timeWeightedNotionalResponse[i].timeWeightedNotional.lastUpdateTimePayFixed +
                    1000,
                lastUpdateTimeReceiveFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .lastUpdateTimeReceiveFixed + 2000,
                storageId: timeWeightedNotionalResponse[i].timeWeightedNotional.storageId
            });
        }

        // when
        vm.prank(_owner);
        ISpreadStorageService(_routerAddress).updateTimeWeightedNotional(timeWeightedNotional);

        // then
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();

        for (uint i; i < timeWeightedNotionalResponseAfter.length; i++) {
            assertEq(
                timeWeightedNotionalResponse[i].key,
                timeWeightedNotionalResponseAfter[i].key,
                "key should be equal"
            );
            assertEq(
                timeWeightedNotionalResponse[i].timeWeightedNotional.timeWeightedNotionalPayFixed + 100e18,
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalPayFixed,
                "timeWeightedNotionalPayFixed should be equal"
            );
            assertEq(
                timeWeightedNotionalResponse[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed + 200e18,
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                "timeWeightedNotionalReceiveFixed should be equal"
            );
            assertEq(
                timeWeightedNotionalResponse[i].timeWeightedNotional.lastUpdateTimePayFixed + 1000,
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.lastUpdateTimePayFixed,
                "lastUpdateTimePayFixed should be equal"
            );
            assertEq(
                timeWeightedNotionalResponse[i].timeWeightedNotional.lastUpdateTimeReceiveFixed + 2000,
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.lastUpdateTimeReceiveFixed,
                "lastUpdateTimeReceiveFixed should be equal"
            );
        }
    }

    function testShouldNotBeAbleToOverrideTimeWeightedNotionalWhenNotOwner() external {
        // given
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();
        SpreadTypes.TimeWeightedNotionalMemory[]
            memory timeWeightedNotional = new SpreadTypes.TimeWeightedNotionalMemory[](
                timeWeightedNotionalResponse.length
            );

        for (uint i; i < timeWeightedNotionalResponse.length; i++) {
            timeWeightedNotional[i] = SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .timeWeightedNotionalPayFixed + 100e18,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .timeWeightedNotionalReceiveFixed + 200e18,
                lastUpdateTimePayFixed: timeWeightedNotionalResponse[i].timeWeightedNotional.lastUpdateTimePayFixed +
                    1000,
                lastUpdateTimeReceiveFixed: timeWeightedNotionalResponse[i]
                    .timeWeightedNotional
                    .lastUpdateTimeReceiveFixed + 2000,
                storageId: timeWeightedNotionalResponse[i].timeWeightedNotional.storageId
            });
        }

        // when
        vm.expectRevert(bytes(IporErrors.CALLER_NOT_OWNER));
        ISpreadStorageService(_routerAddress).updateTimeWeightedNotional(timeWeightedNotional);
    }
}
