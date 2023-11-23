// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/basic/interfaces/ISpreadGenOne.sol";
import "../../contracts/basic/amm/AmmStorageGenOne.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../../contracts/basic/spread/SpreadGenOne.sol";

contract SpreadSmokeGenOne is Test {
    using SafeCast for uint256;
    SpreadGenOne internal _spread;
    MockTestnetToken public stEth;
    AmmStorageGenOne internal _ammStorage;
    ISpreadGenOne.SpreadInputs internal spreadInputsPayFixed;
    ISpreadGenOne.SpreadInputs internal spreadInputsReceiveFixed;

    function setUp() external {
        vm.warp(1700451493);
        stEth = new MockTestnetToken("Mocked stETH", "stETH", 100_000_000 * 1e18, uint8(18));
        _ammStorage = new AmmStorageGenOne(address(this), address(this));

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional = SpreadTypesGenOne
            .TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: 0,
                timeWeightedNotionalReceiveFixed: 0,
                lastUpdateTimePayFixed: block.timestamp - 10 days,
                lastUpdateTimeReceiveFixed: block.timestamp - 10 days,
                storageId: SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days
            });
        SpreadTypesGenOne.TimeWeightedNotionalMemory[]
            memory weightedNotionalInput = new SpreadTypesGenOne.TimeWeightedNotionalMemory[](1);
        weightedNotionalInput[0] = weightedNotional;
        _spread = new SpreadGenOne({
            iporProtocolRouterInput: address(this),
            assetInput: address(stEth),
            timeWeightedNotional: weightedNotionalInput
        });

        spreadInputsPayFixed = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 0,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        spreadInputsReceiveFixed = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 0,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
    }

    function testShouldGetZeroSpreadValue() external {
        // given

        // then
        uint256 payFixed28 = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28 = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60 = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 receiveFixed60 = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90 = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 receiveFixed90 = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.demandSpreadFactor = 500;
        spreadInputsReceiveFixed.demandSpreadFactor = 500;

        // then
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        // then
        assertTrue(payFixed28Before < payFixed28After, "payFixed28Before should be smaller than payFixed28After");
        assertTrue(
            receiveFixed28Before > receiveFixed28After,
            "receiveFixed28Before should be getter than receiveFixed28After"
        );
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        // when
        uint256 payFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        assertTrue(payFixed28Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn60PayFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_60
        });

        // when
        uint256 payFixed60Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        assertTrue(payFixed60Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn90PayFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 2e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_90
        });

        // when
        uint256 payFixed90Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        assertTrue(payFixed90Open > 2e16, "payFixed28Open should be greater than 2e16");
    }

    function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed2() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        uint256 payFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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

        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        uint256 receiveFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        // when
        uint256 receiveFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        assertTrue(receiveFixed28Open < 1e15, "receiveFixed28Open should be less than 1e15");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn60ReceiveFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_60
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        uint256 receiveFixed60Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15, //todo
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_60
        });

        // when
        uint256 receiveFixed60Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        assertTrue(receiveFixed60Open < 1e15, "receiveFixed60Open should be less than 1e15");
    }

    function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn90ReceiveFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 5e16,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_90
        });

        uint256 payFixed28Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90Before = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90Before = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(
            spreadInputsReceiveFixed
        );

        // when
        uint256 receiveFixed90Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
        uint256 payFixed28After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90After = ISpreadGenOne(_spread).calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90After = ISpreadGenOne(_spread).calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 1e15,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_90
        });

        // when
        uint256 receiveFixed90Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        // then
        assertTrue(receiveFixed90Open < 1e15, "receiveFixed90Open should be less than 1e15");
    }

    function testShouldBeAbleToOverrideTimeWaitedNotional() external {
        // given
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse = ISpreadGenOne(_spread)
            .getTimeWeightedNotional();
        SpreadTypesGenOne.TimeWeightedNotionalMemory[] memory timeWeightedNotional = new SpreadTypesGenOne.TimeWeightedNotionalMemory[](
                timeWeightedNotionalResponse.length
            );

        for (uint i; i < timeWeightedNotionalResponse.length; i++) {
            timeWeightedNotional[i] = SpreadTypesGenOne.TimeWeightedNotionalMemory({
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
        ISpreadGenOne(_spread).updateTimeWeightedNotional(timeWeightedNotional);

        // then
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadGenOne(
            _spread
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


    function testShouldNotBeAbleToOverrideTimeWaitedNotionalWhenNotOwner() external {
        // given
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse = ISpreadGenOne(_spread)
            .getTimeWeightedNotional();
        SpreadTypesGenOne.TimeWeightedNotionalMemory[] memory timeWeightedNotional = new SpreadTypesGenOne.TimeWeightedNotionalMemory[](
                timeWeightedNotionalResponse.length
            );

        for (uint i; i < timeWeightedNotionalResponse.length; i++) {
            timeWeightedNotional[i] = SpreadTypesGenOne.TimeWeightedNotionalMemory({
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
        vm.prank(address(_ammStorage));
        vm.expectRevert("Ownable: caller is not the owner");
        ISpreadGenOne(_spread).updateTimeWeightedNotional(timeWeightedNotional);
    }
}
