// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../../contracts/amm/libraries/types/AmmInternalTypes.sol";
import "../../contracts/base/spread/SpreadBaseV1.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";

contract SpreadCloseSwapServiceBaseV1 is Test {
    using SafeCast for uint256;
    SpreadBaseV1 internal _spread;
    MockTestnetToken public stEth;
    AmmStorageBaseV1 internal _ammStorage;

    function setUp() external {
        vm.warp(1700451493);
        stEth = new MockTestnetToken("Mocked stETH", "stETH", 100_000_000 * 1e18, uint8(18));
        _ammStorage = new AmmStorageBaseV1(address(this));

        SpreadTypesBaseV1.TimeWeightedNotionalMemory memory weightedNotional = SpreadTypesBaseV1
            .TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: 0,
                timeWeightedNotionalReceiveFixed: 0,
                lastUpdateTimePayFixed: block.timestamp - 10 days,
                lastUpdateTimeReceiveFixed: block.timestamp - 10 days,
                storageId: SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional28Days
            });
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[]
            memory weightedNotionalInput = new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](1);
        weightedNotionalInput[0] = weightedNotional;
        _spread = new SpreadBaseV1({
            iporProtocolRouterInput: address(this),
            assetInput: address(stEth),
            timeWeightedNotional: weightedNotionalInput
        });
    }

    function testShouldDecreaseTimeWeightedNotionalToZeroWhenPayFixed() external {
        // given
        ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 0,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        uint256 openSwapTimeStamp = block.timestamp + 100 days;
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            openSwapTimeStamp.toUint32()
        );

        vm.warp(openSwapTimeStamp);
        uint256 payFixed28Open = ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        uint256 sumBefore;
        uint256 sumAfter;
        for (uint256 i; i != timeWeightedNotionalResponseAfter.length; i++) {
            sumBefore =
                sumBefore +
                timeWeightedNotionalResponseBefore[i].timeWeightedNotional.timeWeightedNotionalPayFixed;
            sumAfter =
                sumAfter +
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalPayFixed;
        }
        assertTrue(sumBefore == spreadInputsOpen.swapNotional, "sumBefore != spreadInputsOpen.swapNotional");
        assertTrue(sumAfter == 0, "sumAfter != 0");
    }

    function testShouldDecreaseTimeWeightedNotionalToZeroWhenReceiveFixed() external {
        // given
        ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 0,
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        uint256 openSwapTimeStamp = block.timestamp + 100 days;
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            openSwapTimeStamp.toUint32()
        );

        vm.warp(openSwapTimeStamp);
        uint256 payFixed28Open = ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
            1,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        uint256 sumBefore;
        uint256 sumAfter;
        for (uint256 i; i != timeWeightedNotionalResponseAfter.length; i++) {
            sumBefore =
                sumBefore +
                timeWeightedNotionalResponseBefore[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed;
            sumAfter =
                sumAfter +
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed;
        }
        assertTrue(sumBefore == spreadInputsOpen.swapNotional, "sumBefore != spreadInputsOpen.swapNotional");
        assertTrue(sumAfter == 0, "sumAfter != 0");
    }

    function testShouldDecreaseTimeWeightedNotionalWhen2swapsOpensOneCloseWhenPayFixed() external {
        // given
        vm.warp(1000 days);
        ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
            asset: address(stEth),
            swapNotional: 10_000e18,
            baseSpreadPerLeg: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPoolBalance: 1_000_000e18,
            iporIndexValue: 1e16,
            fixedRateCapPerLeg: 0, //todo
            demandSpreadFactor: 1000,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            block.timestamp.toUint32()
        );

        ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(block.timestamp + 10 days);
        ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadBaseV1(
            _spread
        ).getTimeWeightedNotional();

        uint256 sumBefore;
        uint256 sumAfter;
        for (uint256 i; i != timeWeightedNotionalResponseAfter.length; ++i) {
            sumBefore =
                sumBefore +
                timeWeightedNotionalResponseBefore[i].timeWeightedNotional.timeWeightedNotionalPayFixed;
            sumAfter =
                sumAfter +
                timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalPayFixed;
        }

        assertTrue(sumBefore == 20_000e18, "sumBefore != 20_000");
        assertTrue(sumAfter == 10_000e18, "sumAfter != 10_000e18");
    }

        function testShouldDecreaseTimeWeightedNotionalWhen2swapsOpensOneCloseWhenReceiveFixed() external {
            // given
            vm.warp(1000 days);
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: address (stEth),
                swapNotional: 10_000e18,
                baseSpreadPerLeg: 0,
                totalCollateralPayFixed: 10_000e18,
                totalCollateralReceiveFixed: 10_000e18,
                liquidityPoolBalance: 1_000_000e18,
                iporIndexValue: 1e16,
                fixedRateCapPerLeg: 0, //todo
                demandSpreadFactor: 1000,
                tenor: IporTypes.SwapTenor.DAYS_28
            });
            AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
                10,
                11,
                9,
                block.timestamp.toUint32()
            );

            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadBaseV1(
                _spread
            ).getTimeWeightedNotional();

            // when
            vm.warp(block.timestamp + 10 days);
            ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
                1,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            // then
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadBaseV1(
                _spread
            ).getTimeWeightedNotional();

            uint256 sumBefore;
            uint256 sumAfter;
            for (uint256 i; i != timeWeightedNotionalResponseAfter.length; ++i) {
                sumBefore =
                    sumBefore +
                    timeWeightedNotionalResponseBefore[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed;
                sumAfter =
                    sumAfter +
                    timeWeightedNotionalResponseAfter[i].timeWeightedNotional.timeWeightedNotionalReceiveFixed;
            }

            assertTrue(sumBefore == 20_000e18, "sumBefore != 20_000");
            assertTrue(sumAfter == 10_000e18, "sumAfter != 10_000e18");
        }

        function testShouldResetTimeWeightedNotionalToPrevStateWhenClosedLastOpenSwapReceiveFixed() external {
            // given
            uint256 cfgIporPublicationFee = 1e18;
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: address(stEth),
                swapNotional: 10_000e18,
                baseSpreadPerLeg: 0,
                totalCollateralPayFixed: 10_000e18,
                totalCollateralReceiveFixed: 10_000e18,
                liquidityPoolBalance: 1_000_000e18,
                iporIndexValue: 1e16,
                fixedRateCapPerLeg: 0, //todo
                demandSpreadFactor: 1000,
                tenor: IporTypes.SwapTenor.DAYS_28
            });

            vm.warp(1000 days);

            AmmTypes.NewSwap memory newSwap1 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            _ammStorage.updateStorageWhenOpenSwapReceiveFixedInternal(newSwap1, cfgIporPublicationFee);
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            AmmTypes.NewSwap memory newSwap2 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            _ammStorage.updateStorageWhenOpenSwapReceiveFixedInternal(newSwap2, cfgIporPublicationFee);
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            AmmTypes.NewSwap memory newSwap3 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
                3,
                0,
                2,
                newSwap3.openTimestamp.toUint32()
            );

            // when
            ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
                1,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            //then
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            assertTrue(
                timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed ==
                    18214000000000000000000,
                "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed != 18214000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed ==
                    86832000,
                "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed != 86832000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed ==
                    24961000000000000000000,
                "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed != 24961000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed ==
                    87264000,
                "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed != 87264000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed ==
                    18213000000000000000000,
                "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalReceiveFixed != 18213000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed ==
                    86832000,
                "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimeReceiveFixed != 87264000"
            );
        }

        function testShouldResetTimeWeightedNotionalToPrevStateWhenClosedLastOpenSwapPayFixed() external {
            // given
            uint256 cfgIporPublicationFee = 1e18;
            ISpreadBaseV1.SpreadInputs memory spreadInputsOpen = ISpreadBaseV1.SpreadInputs({
                asset: address(stEth),
                swapNotional: 10_000e18,
                baseSpreadPerLeg: 0,
                totalCollateralPayFixed: 10_000e18,
                totalCollateralReceiveFixed: 10_000e18,
                liquidityPoolBalance: 1_000_000e18,
                iporIndexValue: 1e16,
                fixedRateCapPerLeg: 0, //todo
                demandSpreadFactor: 1000,
                tenor: IporTypes.SwapTenor.DAYS_28
            });

            vm.warp(1000 days);

            AmmTypes.NewSwap memory newSwap1 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            _ammStorage.updateStorageWhenOpenSwapPayFixedInternal(newSwap1, cfgIporPublicationFee);
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            AmmTypes.NewSwap memory newSwap2 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            _ammStorage.updateStorageWhenOpenSwapPayFixedInternal(newSwap2, cfgIporPublicationFee);
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            AmmTypes.NewSwap memory newSwap3 = AmmTypes.NewSwap(
                address(this),
                block.timestamp,
                1_000e18,
                100_000e18,
                10e18,
                1e18,
                25, //liquidationDepositAmount
                1e18,
                1e18,
                IporTypes.SwapTenor.DAYS_28
            );
            ISpreadBaseV1(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
                3,
                0,
                2,
                newSwap3.openTimestamp.toUint32()
            );

            // when

            ISpreadBaseV1(_spread).updateTimeWeightedNotionalOnClose(
                0,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            //then
            SpreadTypesBaseV1.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadBaseV1(_spread)
                    .getTimeWeightedNotional();

            assertTrue(
                timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
                    18214000000000000000000,
                "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 18214000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed == 86832000,
                "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 86832000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
                    24961000000000000000000,
                "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 24961000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed == 87264000,
                "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 87264000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
                    18213000000000000000000,
                "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 18213000000000000000000"
            );
            assertTrue(
                timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed == 86832000,
                "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 87264000"
            );
        }
}
