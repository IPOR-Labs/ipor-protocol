// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/amm/libraries/types/AmmInternalTypes.sol";
import "../../contracts/basic/spread/SpreadGenOne.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../../contracts/basic/amm/AmmStorageGenOne.sol";

contract SpreadCloseSwapServiceGenOne is Test {
    using SafeCast for uint256;
    SpreadGenOne internal _spread;
    MockTestnetToken public stEth;
    AmmStorageGenOne internal _ammStorage;

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
    }

    function testShouldDecreaseTimeWeightedNotionalToZeroWhenPayFixed() external {
        // given
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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
        uint256 payFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadGenOne(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadGenOne(
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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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
        uint256 payFixed28Open = ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadGenOne(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
            1,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadGenOne(
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
        ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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

        ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadGenOne(
            _spread
        ).getTimeWeightedNotional();

        // when
        vm.warp(block.timestamp + 10 days);
        ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(_ammStorage)
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadGenOne(
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
            ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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

            ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadGenOne(
                _spread
            ).getTimeWeightedNotional();

            // when
            vm.warp(block.timestamp + 10 days);
            ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
                1,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            // then
            SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadGenOne(
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
            ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadGenOne(_spread)
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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRateReceiveFixed(spreadInputsOpen);

            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadGenOne(_spread)
                    .getTimeWeightedNotional();

            AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
                3,
                0,
                2,
                newSwap3.openTimestamp.toUint32()
            );

            // when
            ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
                1,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            //then
            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadGenOne(_spread)
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
            ISpreadGenOne.SpreadInputs memory spreadInputsOpen = ISpreadGenOne.SpreadInputs({
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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

            vm.warp(block.timestamp + 5 days);
            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadGenOne(_spread)
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
            ISpreadGenOne(_spread).calculateAndUpdateOfferedRatePayFixed(spreadInputsOpen);

            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadGenOne(_spread)
                    .getTimeWeightedNotional();

            AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
                3,
                0,
                2,
                newSwap3.openTimestamp.toUint32()
            );

            // when

            ISpreadGenOne(_spread).updateTimeWeightedNotionalOnClose(
                0,
                IporTypes.SwapTenor.DAYS_28,
                spreadInputsOpen.swapNotional,
                closedSwap,
                address(_ammStorage)
            );

            //then
            SpreadTypesGenOne.TimeWeightedNotionalResponse[]
                memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadGenOne(_spread)
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
