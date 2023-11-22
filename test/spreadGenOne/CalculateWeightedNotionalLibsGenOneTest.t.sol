// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/basic/spread/CalculateTimeWeightedNotionalLibsGenOne.sol";
import "../TestCommons.sol";

contract CalculateWeightedNotionalLibsGenOneTest is TestCommons {
    SpreadStorageLibsGenOne.StorageId internal _storageIdIterationItem;

    SpreadStorageLibsGenOne.StorageId[] internal _storageIdEnums = [
    SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days,
    SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days,
    SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days
    ];

    modifier _parameterizedStorageId() {
        uint256 length = _storageIdEnums.length;
        for (uint256 i; i != length; ++i) {
            _storageIdIterationItem = _storageIdEnums[i];
            _;
        }
    }

    function testCalculateLpDepth(uint256 totalCollateralPayFixed, uint256 totalCollateralReceiveFixed) public {
        // given
        uint256 lpBalance = 100_000_000 * 1e18;
        vm.assume(totalCollateralPayFixed >= 0);
        vm.assume(totalCollateralPayFixed < 1_000_000);
        vm.assume(totalCollateralReceiveFixed >= 0);
        vm.assume(totalCollateralReceiveFixed < 1_000_000);

        // when
        uint256 lpDepth = CalculateTimeWeightedNotionalLibsGenOne.calculateLpDepth(
            lpBalance,
            totalCollateralPayFixed * 1e18,
            totalCollateralReceiveFixed * 1e18
        );

        // then
        assertTrue(lpDepth > 0, "lpDepth should be greater than 0");
        assertTrue(lpDepth <= lpBalance, "lpDepth should be less than lpBalance");
    }

    function testShouldReturnZeroWhenTimeFromLastUpdateBiggerThanMaturity(uint256 timeFromLastUpdate, uint256 tenorInSeconds)
        public
    {
        // given
        uint256 weightedNotional = 100_000_000 * 1e18;
        vm.assume(timeFromLastUpdate > 0);
        vm.assume(timeFromLastUpdate < 10_000);
        vm.assume(tenorInSeconds >= 0);
        vm.assume(tenorInSeconds < 1_000);
        vm.assume(timeFromLastUpdate > tenorInSeconds);

        // when
        uint256 result = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional,
            timeFromLastUpdate,
            tenorInSeconds
        );

        // then
        assertTrue(result == 0, "result should be 0");
    }

    function testShouldReturnValueLessThanWeightedNotionalWhenTimeFromLastUpdateLessThanMaturity(
        uint256 timeFromLastUpdate,
        uint256 tenorInSeconds
    ) public {
        // given
        uint256 weightedNotional = 100_000_000 * 1e18;
        vm.assume(timeFromLastUpdate > 0);
        vm.assume(timeFromLastUpdate < 3 days);
        vm.assume(tenorInSeconds > 0);
        vm.assume(tenorInSeconds < 3 days);
        vm.assume(timeFromLastUpdate < tenorInSeconds);

        // when
        uint256 result = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional,
            timeFromLastUpdate,
            tenorInSeconds
        );

        // then
        assertTrue(result > 0, "result should be greater than 0");
        assertTrue(result < weightedNotional, "result should be less than weightedNotional");
    }

    function testShouldSaveWeightedNotionalReceiveFixed28DaysEqualSwapNationalWhenFirstTimeSave()
        public
        _parameterizedStorageId
    {
        // given
        uint256 newSwapNotional = 100_000;
        uint256 blockTimestamp = 1000;

        vm.warp(blockTimestamp);

        newSwapNotional = newSwapNotional * 1e18;

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        // when
        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalReceiveFixed(
            SpreadTypesGenOne.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: weightedNotionalBefore.timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: weightedNotionalBefore.lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: weightedNotionalBefore.timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: weightedNotionalBefore.lastUpdateTimeReceiveFixed,
                storageId: weightedNotionalBefore.storageId
            }),
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        assertEq(
            weightedNotionalBefore.timeWeightedNotionalReceiveFixed,
            0,
            "timeWeightedNotionalReceiveFixed should be equal 0"
        );

        assertEq(
            weightedNotionalAfter.timeWeightedNotionalReceiveFixed,
            newSwapNotional,
            "timeWeightedNotionalReceiveFixed should be equal newSwapNotional"
        );
        assertEq(
            weightedNotionalAfter.lastUpdateTimeReceiveFixed,
            block.timestamp,
            "lastUpdateTimeReceiveFixed should be equal block.timestamp"
        );
    }

    function testShouldSaveWeightedNotionalPayFixed28DaysEqualSwapNationalWhenFirstTimeSave()
        public
        _parameterizedStorageId
    {
        // given
        uint256 newSwapNotional = 100_000;
        uint256 blockTimestamp = 1000;

        vm.warp(blockTimestamp);

        newSwapNotional = newSwapNotional * 1e18;

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        // when
        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalPayFixed(
            SpreadTypesGenOne.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: weightedNotionalBefore.timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: weightedNotionalBefore.lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: weightedNotionalBefore.timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: weightedNotionalBefore.lastUpdateTimeReceiveFixed,
                storageId: weightedNotionalBefore.storageId
            }),
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        assertEq(weightedNotionalBefore.timeWeightedNotionalPayFixed, 0, "timeWeightedNotionalReceiveFixed should be equal 0");

        assertEq(
            weightedNotionalAfter.timeWeightedNotionalPayFixed,
            newSwapNotional,
            "timeWeightedNotionalReceiveFixed should be equal newSwapNotional"
        );
        assertEq(
            weightedNotionalAfter.lastUpdateTimePayFixed,
            block.timestamp,
            "lastUpdateTimeReceiveFixed should be equal block.timestamp"
        );
    }

    function testShouldSaveWeightedNotionalReceiveFixed28DaysEqualSwapNationalWhenFirstTimeSaveAndSwapNationalIsNotZero()
        public
        _parameterizedStorageId
    {
        // given
        uint256 newSwapNotional = 100_000;
        uint256 blockTimestamp = 1000;
        vm.warp(blockTimestamp);

        newSwapNotional = newSwapNotional * 1e18;

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadTypesGenOne.TimeWeightedNotionalMemory({
            timeWeightedNotionalPayFixed: 0,
            timeWeightedNotionalReceiveFixed: 1_000_000 * 1e18,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalReceiveFixed(
            weightedNotionalBefore,
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        assertTrue(
            weightedNotionalAfter.timeWeightedNotionalReceiveFixed <
                weightedNotionalBefore.timeWeightedNotionalReceiveFixed + newSwapNotional,
            "timeWeightedNotionalReceiveFixed should be less than weightedNotionalBefore + newSwapNotional"
        );
        assertTrue(
            weightedNotionalAfter.timeWeightedNotionalReceiveFixed > newSwapNotional,
            "timeWeightedNotionalReceiveFixed should be greater than newSwapNotional"
        );
    }

    function testShouldSaveWeightedNotionalPayFixed28DaysEqualSwapNationalWhenFirstTimeSaveAndSwapNationalIsNotZero()
        public
        _parameterizedStorageId
    {
        // given
        uint256 newSwapNotional = 100_000;
        uint256 blockTimestamp = 1000;
        vm.warp(blockTimestamp);

        newSwapNotional = newSwapNotional * 1e18;

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadTypesGenOne.TimeWeightedNotionalMemory({
            timeWeightedNotionalPayFixed: 1_000_000 * 1e18,
            timeWeightedNotionalReceiveFixed: 0,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalPayFixed(weightedNotionalBefore, newSwapNotional, 28 days);

        // then
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );
    }

    function testShouldReturnWeightedNotionalWhenCalculationFor90DaysTenor() public {
        // given
        uint256 timestamp = 120 days;
        vm.warp(timestamp);
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days,
            weightedNotional28Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days,
            weightedNotional60Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days,
            weightedNotional90Days
        );

        SpreadStorageLibsGenOne.StorageId[] memory storageIds = new SpreadStorageLibsGenOne.StorageId[](3);
        storageIds[0] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days;
        storageIds[1] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days;
        storageIds[2] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibsGenOne
            .getTimeWeightedNotional(storageIds, maturities, 90 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            10 days,
            90 days
        );

        assertTrue(
            timeWeightedNotionalPayFixed <
                weightedNotional28Days.timeWeightedNotionalPayFixed +
                    weightedNotional60Days.timeWeightedNotionalPayFixed +
                    weightedNotional90Days.timeWeightedNotionalPayFixed,
            "timeWeightedNotionalPayFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalPayFixed,
            timeWeightedNotionalPayFixed28DaysResult +
                timeWeightedNotionalPayFixed60DaysResult +
                timeWeightedNotionalPayFixed90DaysResult,
            "timeWeightedNotionalPayFixed should be equal to timeWeightedNotionalPayFixed28DaysResult + timeWeightedNotionalPayFixed90DaysResult"
        );

        assertTrue(
            timeWeightedNotionalReceiveFixed <
                weightedNotional28Days.timeWeightedNotionalReceiveFixed +
                    weightedNotional60Days.timeWeightedNotionalReceiveFixed +
                    weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            "timeWeightedNotionalReceiveFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalReceiveFixed,
            timeWeightedNotionalReceiveFixed28DaysResult +
                timeWeightedNotionalReceiveFixed60DaysResult +
                timeWeightedNotionalReceiveFixed90DaysResult,
            "timeWeightedNotionalReceiveFixed should be equal to timeWeightedNotionalReceiveFixed28DaysResult + timeWeightedNotionalReceiveFixed90DaysResult"
        );
    }

    function testShouldReturnWeightedNotionalWhenCalculationFor60DaysTenor() public {
        // given
        uint256 timestamp = 120 days;
        vm.warp(timestamp);
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days,
            weightedNotional28Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days,
            weightedNotional60Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days,
            weightedNotional90Days
        );

        SpreadStorageLibsGenOne.StorageId[] memory storageIds = new SpreadStorageLibsGenOne.StorageId[](3);
        storageIds[0] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days;
        storageIds[1] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days;
        storageIds[2] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibsGenOne
            .getTimeWeightedNotional(storageIds, maturities, 60 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            10 days,
            90 days
        );

        assertTrue(
            timeWeightedNotionalPayFixed <
            weightedNotional28Days.timeWeightedNotionalPayFixed +
            weightedNotional60Days.timeWeightedNotionalPayFixed +
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            "timeWeightedNotionalPayFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalPayFixed,
            timeWeightedNotionalPayFixed28DaysResult +
            timeWeightedNotionalPayFixed60DaysResult +
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            "timeWeightedNotionalPayFixed should be equal to timeWeightedNotionalPayFixed28DaysResult + timeWeightedNotionalPayFixed90DaysResult"
        );

        assertTrue(
            timeWeightedNotionalReceiveFixed <
            weightedNotional28Days.timeWeightedNotionalReceiveFixed +
            weightedNotional60Days.timeWeightedNotionalReceiveFixed +
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            "timeWeightedNotionalReceiveFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalReceiveFixed,
            timeWeightedNotionalReceiveFixed28DaysResult +
            timeWeightedNotionalReceiveFixed60DaysResult +
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            "timeWeightedNotionalReceiveFixed should be equal to timeWeightedNotionalReceiveFixed28DaysResult + timeWeightedNotionalReceiveFixed90DaysResult"
        );
    }

    function testShouldReturnWeightedNotionalWhenCalculationFor28DaysTenor() public {
        // given
        uint256 timestamp = 120 days;
        vm.warp(timestamp);
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days
        );
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days,
            weightedNotional28Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days,
            weightedNotional60Days
        );

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days,
            weightedNotional90Days
        );

        SpreadStorageLibsGenOne.StorageId[] memory storageIds = new SpreadStorageLibsGenOne.StorageId[](3);
        storageIds[0] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days;
        storageIds[1] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days;
        storageIds[2] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibsGenOne
            .getTimeWeightedNotional(storageIds, maturities, 28 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibsGenOne.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            10 days,
            90 days
        );

        assertTrue(
            timeWeightedNotionalPayFixed <
            weightedNotional28Days.timeWeightedNotionalPayFixed +
            weightedNotional60Days.timeWeightedNotionalPayFixed +
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            "timeWeightedNotionalPayFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalPayFixed,
            timeWeightedNotionalPayFixed28DaysResult +
            weightedNotional60Days.timeWeightedNotionalPayFixed +
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            "timeWeightedNotionalPayFixed should be equal to timeWeightedNotionalPayFixed28DaysResult + timeWeightedNotionalPayFixed90DaysResult"
        );

        assertTrue(
            timeWeightedNotionalReceiveFixed <
            weightedNotional28Days.timeWeightedNotionalReceiveFixed +
            weightedNotional60Days.timeWeightedNotionalReceiveFixed +
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            "timeWeightedNotionalReceiveFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            timeWeightedNotionalReceiveFixed,
            timeWeightedNotionalReceiveFixed28DaysResult +
            weightedNotional60Days.timeWeightedNotionalReceiveFixed +
            weightedNotional90Days.timeWeightedNotionalReceiveFixed,
            "timeWeightedNotionalReceiveFixed should be equal to timeWeightedNotionalReceiveFixed28DaysResult + timeWeightedNotionalReceiveFixed90DaysResult"
        );
    }

    function _getWeightedNotionalMemory(uint256 seed, SpreadStorageLibsGenOne.StorageId storageId)
        private
        returns (SpreadTypesGenOne.TimeWeightedNotionalMemory memory)
    {
        return
            SpreadTypesGenOne.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: seed * 1e18,
                lastUpdateTimePayFixed: seed * 2000,
                timeWeightedNotionalReceiveFixed: seed * 3e18,
                lastUpdateTimeReceiveFixed: seed * 4000,
                storageId: storageId
            });
    }
}
