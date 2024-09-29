// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "forge-std/Test.sol";

import {ISpreadBaseV1} from "../../../contracts/base/interfaces/ISpreadBaseV1.sol";
import {SpreadUsdc} from "../../../contracts/chains/arbitrum/amm-usdc/SpreadUsdc.sol";
import {SpreadTypesBaseV1} from "../../../contracts/base/types/SpreadTypesBaseV1.sol";
import {IporTypes} from "../../../contracts/interfaces/types/IporTypes.sol";
import {IporErrors} from "../../../contracts/libraries/errors/IporErrors.sol";

contract SpreadUsdcSmokeTest is Test {
    address private constant _USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address internal IporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    ISpreadBaseV1.SpreadInputs internal spreadInputsPayFixed;
    ISpreadBaseV1.SpreadInputs internal spreadInputsReceiveFixed;
    SpreadUsdc private _spread;

    function setUp() external {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 209413278);
        _spread = new SpreadUsdc(address(this), _USDC, new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](0));

        spreadInputsPayFixed = ISpreadBaseV1.SpreadInputs({
            asset: _USDC,
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
        spreadInputsReceiveFixed = ISpreadBaseV1.SpreadInputs({
            asset: _USDC,
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
        uint256 payFixed28 = _spread.calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed28 = _spread.calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
        uint256 payFixed60 = _spread.calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed60 = _spread.calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

        spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
        uint256 payFixed90 = _spread.calculateOfferedRatePayFixed(spreadInputsPayFixed);
        uint256 receiveFixed90 = _spread.calculateOfferedRateReceiveFixed(spreadInputsReceiveFixed);

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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.demandSpreadFactor = 500;
            spreadInputsReceiveFixed.demandSpreadFactor = 500;

            // then
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_28;
            // when
            uint256 payFixed28Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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
            uint256 payFixed28Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(payFixed28Open > 2e16, "payFixed28Open should be greater than 2e16");
        }

        function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn60PayFixed() external {
            // given
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsOpen.tenor = IporTypes.SwapTenor.DAYS_60;
            // when
            uint256 payFixed60Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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
            uint256 payFixed60Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(payFixed60Open > 2e16, "payFixed28Open should be greater than 2e16");
        }

        function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn90PayFixed() external {
            // given
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            // when
            uint256 payFixed90Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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
            uint256 payFixed90Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(payFixed90Open > 2e16, "payFixed28Open should be greater than 2e16");
        }

        function testShouldSpreadPayFixedIncreaseWhenOneSwapOpenOn28PayFixed2() external {
            // given
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            // when
            uint256 payFixed28Open = _spread.calculateAndUpdateOfferedRatePayFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            // when
            uint256 receiveFixed28Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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
            uint256 receiveFixed28Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(receiveFixed28Open < 1e15, "receiveFixed28Open should be less than 1e15");
        }

        function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn60ReceiveFixed() external {
            // given
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            // when
            uint256 receiveFixed60Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
                swapNotional: 10_000e18,
                baseSpreadPerLeg: 0,
                totalCollateralPayFixed: 10_000e18,
                totalCollateralReceiveFixed: 10_000e18,
                liquidityPoolBalance: 1_000_000e18,
                iporIndexValue: 1e16,
                fixedRateCapPerLeg: 1e15,
                demandSpreadFactor: 1000,
                tenor: IporTypes.SwapTenor.DAYS_60
            });

            // when
            uint256 receiveFixed60Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(receiveFixed60Open < 1e15, "receiveFixed60Open should be less than 1e15");
        }

        function testShouldSpreadReceiveFixedIncreaseWhenOneSwapOpenOn90ReceiveFixed() external {
            // given
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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

            uint256 payFixed28Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90Before = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90Before = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            // when
            uint256 receiveFixed90Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_28;
            uint256 payFixed28After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed28After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_60;
            uint256 payFixed60After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed60After = _spread.calculateOfferedRateReceiveFixed(
                spreadInputsReceiveFixed
            );

            spreadInputsPayFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            spreadInputsReceiveFixed.tenor = IporTypes.SwapTenor.DAYS_90;
            uint256 payFixed90After = _spread.calculateOfferedRatePayFixed(
                spreadInputsPayFixed
            );
            uint256 receiveFixed90After = _spread.calculateOfferedRateReceiveFixed(
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
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: _USDC,
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
            uint256 receiveFixed90Open = _spread.calculateAndUpdateOfferedRateReceiveFixed(
                spreadInputsOpen
            );

            // then
            assertTrue(receiveFixed90Open < 1e15, "receiveFixed90Open should be less than 1e15");
        }

        function testShouldBeAbleToOverrideTimeWeightedNotional() external {
            // given
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse = _spread.getTimeWeightedNotional();
            SpreadTypesBaseV1.TimeWeightedNotionalMemory[]
                memory timeWeightedNotional = new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](
                    timeWeightedNotionalResponse.length
                );

            for (uint i; i < timeWeightedNotionalResponse.length; i++) {
                timeWeightedNotional[i] = SpreadTypesBaseV1.TimeWeightedNotionalMemory({
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
            _spread.updateTimeWeightedNotional(timeWeightedNotional);

            // then
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = _spread.getTimeWeightedNotional();

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

}
