// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/amm/spread/CalculateTimeWeightedNotionalLibs.sol";
import "../TestCommons.sol";

contract CalculateWeightedNotionalLibsTest is TestCommons {
    SpreadStorageLibs.StorageId internal _storageIdIterationItem;

    SpreadStorageLibs.StorageId[] internal _storageIdEnums = [
        SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai,
        SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc,
        SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt,
        SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai,
        SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc,
        SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt
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
        uint256 lpDepth = CalculateTimeWeightedNotionalLibs.calculateLpDepth(
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
        uint256 result = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
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
        uint256 result = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
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

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        // when
        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
            SpreadTypes.TimeWeightedNotionalMemory({
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
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
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

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );

        // when
        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(
            SpreadTypes.TimeWeightedNotionalMemory({
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
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
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

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadTypes.TimeWeightedNotionalMemory({
            timeWeightedNotionalPayFixed: 0,
            timeWeightedNotionalReceiveFixed: 1_000_000 * 1e18,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
            weightedNotionalBefore,
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
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

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalBefore = SpreadTypes.TimeWeightedNotionalMemory({
            timeWeightedNotionalPayFixed: 1_000_000 * 1e18,
            timeWeightedNotionalReceiveFixed: 0,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(weightedNotionalBefore, newSwapNotional, 28 days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(
            _storageIdIterationItem
        );
    }

    function testShouldReturnWeightedNotionalWhenCalculationFor90DaysTenor() public {
        // given
        uint256 timestamp = 120 days;
        vm.warp(timestamp);
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai,
            weightedNotional28Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai,
            weightedNotional60Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai,
            weightedNotional90Days
        );

        SpreadStorageLibs.StorageId[] memory storageIds = new SpreadStorageLibs.StorageId[](3);
        storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
        storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
        storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibs
            .getTimeWeightedNotional(storageIds, maturities, 90 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai,
            weightedNotional28Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai,
            weightedNotional60Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai,
            weightedNotional90Days
        );

        SpreadStorageLibs.StorageId[] memory storageIds = new SpreadStorageLibs.StorageId[](3);
        storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
        storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
        storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibs
            .getTimeWeightedNotional(storageIds, maturities, 60 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai
        );
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai,
            weightedNotional28Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai,
            weightedNotional60Days
        );

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
            SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai,
            weightedNotional90Days
        );

        SpreadStorageLibs.StorageId[] memory storageIds = new SpreadStorageLibs.StorageId[](3);
        storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
        storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
        storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) = CalculateTimeWeightedNotionalLibs
            .getTimeWeightedNotional(storageIds, maturities, 28 days);

        // then

        uint256 timeWeightedNotionalPayFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalPayFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalPayFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional90Days.timeWeightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 timeWeightedNotionalReceiveFixed28DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional28Days.timeWeightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 timeWeightedNotionalReceiveFixed60DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            weightedNotional60Days.timeWeightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 timeWeightedNotionalReceiveFixed90DaysResult = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
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

    function _getWeightedNotionalMemory(uint256 seed, SpreadStorageLibs.StorageId storageId)
        private
        returns (SpreadTypes.TimeWeightedNotionalMemory memory)
    {
        return
            SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: seed * 1e18,
                lastUpdateTimePayFixed: seed * 2000,
                timeWeightedNotionalReceiveFixed: seed * 3e18,
                lastUpdateTimeReceiveFixed: seed * 4000,
                storageId: storageId
            });
    }
}
