// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "./SpreadBaseTestUtils.sol";
import "./SpreadTestSystem.sol";
import "contracts/amm/spread/ISpreadCloseSwapService.sol";
import "contracts/amm/spread/ISpreadStorageLens.sol";
import "contracts/amm/libraries/types/AmmInternalTypes.sol";

contract SpreadCloseSwapServiceTest is SpreadBaseTestUtils {
    using SafeCast for uint256;
    SpreadTestSystem internal _spreadTestSystem;
    address internal _ammAddress;
    address internal _routerAddress;
    address internal _owner;

    function setUp() external {
        _ammAddress = _getUserAddress(10);
        _spreadTestSystem = new SpreadTestSystem(_ammAddress);
        _routerAddress = address(_spreadTestSystem.router());
        _owner = _spreadTestSystem.owner();
    }

    function testShouldDecreaseTimeWeightedNotionalToZeroWhenPayFixed() external {
        // given
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });
        uint256 openSwapTimeStamp = block.timestamp + 100 days;
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            openSwapTimeStamp.toUint32()
        );

        vm.warp(openSwapTimeStamp);
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(0)
        );

        // then
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadStorageLens(
            _routerAddress
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
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });
        uint256 openSwapTimeStamp = block.timestamp + 100 days;
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            openSwapTimeStamp.toUint32()
        );

        vm.warp(openSwapTimeStamp);
        vm.prank(_ammAddress);
        uint256 payFixed28Open = ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();

        // when
        vm.warp(openSwapTimeStamp + 27 days);
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            1,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(0)
        );

        // then
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadStorageLens(
            _routerAddress
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
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            block.timestamp.toUint32()
        );

        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();

        // when
        vm.warp(block.timestamp + 10 days);
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(0)
        );

        // then
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadStorageLens(
            _routerAddress
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
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });
        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            10,
            11,
            9,
            block.timestamp.toUint32()
        );

        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseBefore = ISpreadStorageLens(
            _routerAddress
        ).getTimeWeightedNotional();

        // when
        vm.warp(block.timestamp + 10 days);
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            1,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            address(0)
        );

        // then
        SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponseAfter = ISpreadStorageLens(
            _routerAddress
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
        IAmmStorage ammStorage = IAmmStorage(_spreadTestSystem.ammStorage());
        uint256 cfgIporPublicationFee = 1e18;
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });

        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap1 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_owner);
        ammStorage.updateStorageWhenOpenSwapReceiveFixedInternal(newSwap1, cfgIporPublicationFee);
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        vm.warp(block.timestamp + 5 days);
        AmmTypes.NewSwap memory newSwap2 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_owner);
        ammStorage.updateStorageWhenOpenSwapReceiveFixedInternal(newSwap2, cfgIporPublicationFee);
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        vm.warp(block.timestamp + 5 days);
        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadStorageLens(_routerAddress)
                .getTimeWeightedNotional();

        AmmTypes.NewSwap memory newSwap3 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRateReceiveFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadStorageLens(_routerAddress)
                .getTimeWeightedNotional();

        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            3,
            0,
            2,
            newSwap3.openTimestamp.toUint32()
        );

        // when
        address ammStorageAddress = _spreadTestSystem.ammStorage();
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            1,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            ammStorageAddress
        );

        //then
        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadStorageLens(_routerAddress)
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
        IAmmStorage ammStorage = IAmmStorage(_spreadTestSystem.ammStorage());
        uint256 cfgIporPublicationFee = 1e18;
        address dai = address(_spreadTestSystem.dai());
        IporTypes.SpreadInputs memory spreadInputsOpen = IporTypes.SpreadInputs({
            asset: dai,
            swapNotional: 10_000e18,
            maxLeverage: 1_000e18,
            maxLpCollateralRatioPerLegRate: 1e18,
            baseSpread: 0,
            totalCollateralPayFixed: 10_000e18,
            totalCollateralReceiveFixed: 10_000e18,
            liquidityPool: 1_000_000e18,
            totalNotionalPayFixed: 100_000e18,
            totalNotionalReceiveFixed: 100_000e18,
            indexValue: 1e16,
            cap: 0 //todo
        });

        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap1 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_owner);
        ammStorage.updateStorageWhenOpenSwapPayFixedInternal(newSwap1, cfgIporPublicationFee);
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        vm.warp(block.timestamp + 5 days);
        AmmTypes.NewSwap memory newSwap2 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_owner);
        ammStorage.updateStorageWhenOpenSwapPayFixedInternal(newSwap2, cfgIporPublicationFee);
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        vm.warp(block.timestamp + 5 days);
        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseBeforeOpenLastSwap = ISpreadStorageLens(_routerAddress)
                .getTimeWeightedNotional();

        AmmTypes.NewSwap memory newSwap3 = AmmTypes.NewSwap(
            _owner,
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
        vm.prank(_ammAddress);
        ISpread28Days(_routerAddress).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputsOpen);

        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseAfterOpenLastSwap = ISpreadStorageLens(_routerAddress)
                .getTimeWeightedNotional();

        AmmInternalTypes.OpenSwapItem memory closedSwap = AmmInternalTypes.OpenSwapItem(
            3,
            0,
            2,
            newSwap3.openTimestamp.toUint32()
        );

        // when
        address ammStorageAddress = _spreadTestSystem.ammStorage();
        vm.prank(_ammAddress);
        ISpreadCloseSwapService(_routerAddress).updateTimeWeightedNotionalOnClose(
            dai,
            0,
            IporTypes.SwapTenor.DAYS_28,
            spreadInputsOpen.swapNotional,
            closedSwap,
            ammStorageAddress
        );

        //then
        SpreadTypes.TimeWeightedNotionalResponse[]
            memory timeWeightedNotionalResponseAfterCloseLastSwap = ISpreadStorageLens(_routerAddress)
                .getTimeWeightedNotional();

        assertTrue(
            timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
                18214000000000000000000,
            "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 18214000000000000000000"
        );
        assertTrue(
            timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed ==
            86832000,
            "timeWeightedNotionalResponseBeforeOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 86832000"
        );
        assertTrue(
            timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
            24961000000000000000000,
            "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 24961000000000000000000"
        );
        assertTrue(
            timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed ==
            87264000,
            "timeWeightedNotionalResponseAfterOpenLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 87264000"
        );
        assertTrue(
            timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed ==
            18213000000000000000000,
            "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.timeWeightedNotionalPayFixed != 18213000000000000000000"
        );
        assertTrue(
            timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed ==
            86832000,
            "timeWeightedNotionalResponseAfterCloseLastSwap[0].timeWeightedNotional.lastUpdateTimePayFixed != 87264000"
        );
    }
}
