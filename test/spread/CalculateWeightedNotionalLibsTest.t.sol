// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../contracts/amm/spread/CalculateWeightedNotionalLibs.sol";
import "../TestCommons.sol";

contract CalculateWeightedNotionalLibsTest is TestCommons {
    SpreadStorageLibs.StorageId internal _storageIdIterationItem;

    SpreadStorageLibs.StorageId[] internal _storageIdEnums = [
        SpreadStorageLibs.StorageId.WeightedNotional28DaysDai,
        SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdc,
        SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdt,
        SpreadStorageLibs.StorageId.WeightedNotional90DaysDai,
        SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdc,
        SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdt
    ];

    modifier _parameterizedStorageId() {
        uint256 length = _storageIdEnums.length;
        for (uint256 i = 0; i < length; ++i) {
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
        uint256 lpDepth = CalculateWeightedNotionalLibs.calculateLpDepth(
            lpBalance,
            totalCollateralPayFixed * 1e18,
            totalCollateralReceiveFixed * 1e18
        );

        // then
        assertTrue(lpDepth > 0, "lpDepth should be greater than 0");
        assertTrue(lpDepth <= lpBalance, "lpDepth should be less than lpBalance");
    }

    function testShouldReturnZeroWhenTimeFromLastUpdateBiggerThanMaturity(uint256 timeFromLastUpdate, uint256 maturity)
        public
    {
        // given
        uint256 weightedNotional = 100_000_000 * 1e18;
        vm.assume(timeFromLastUpdate > 0);
        vm.assume(timeFromLastUpdate < 10_000);
        vm.assume(maturity >= 0);
        vm.assume(maturity < 1_000);
        vm.assume(timeFromLastUpdate > maturity);

        // when
        uint256 result = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional,
            timeFromLastUpdate,
            maturity
        );

        // then
        assertTrue(result == 0, "result should be 0");
    }

    function testShouldReturnValueLessThanWeightedNotionalWhenTimeFromLastUpdateLessThanMaturity(
        uint256 timeFromLastUpdate,
        uint256 maturity
    ) public {
        // given
        uint256 weightedNotional = 100_000_000 * 1e18;
        vm.assume(timeFromLastUpdate > 0);
        vm.assume(timeFromLastUpdate < 3 days);
        vm.assume(maturity > 0);
        vm.assume(maturity < 3 days);
        vm.assume(timeFromLastUpdate < maturity);

        // when
        uint256 result = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional,
            timeFromLastUpdate,
            maturity
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

        SpreadTypes.WeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );

        // when
        CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
            SpreadTypes.WeightedNotionalMemory({
                weightedNotionalPayFixed: weightedNotionalBefore.weightedNotionalPayFixed,
                lastUpdateTimePayFixed: weightedNotionalBefore.lastUpdateTimePayFixed,
                weightedNotionalReceiveFixed: weightedNotionalBefore.weightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: weightedNotionalBefore.lastUpdateTimeReceiveFixed,
                storageId: weightedNotionalBefore.storageId
            }),
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypes.WeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );

        assertEq(
            weightedNotionalBefore.weightedNotionalReceiveFixed,
            0,
            "weightedNotionalReceiveFixed should be equal 0"
        );

        assertEq(
            weightedNotionalAfter.weightedNotionalReceiveFixed,
            newSwapNotional,
            "weightedNotionalReceiveFixed should be equal newSwapNotional"
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

        SpreadTypes.WeightedNotionalMemory memory weightedNotionalBefore = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );

        // when
        CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(
            SpreadTypes.WeightedNotionalMemory({
                weightedNotionalPayFixed: weightedNotionalBefore.weightedNotionalPayFixed,
                lastUpdateTimePayFixed: weightedNotionalBefore.lastUpdateTimePayFixed,
                weightedNotionalReceiveFixed: weightedNotionalBefore.weightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: weightedNotionalBefore.lastUpdateTimeReceiveFixed,
                storageId: weightedNotionalBefore.storageId
            }),
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypes.WeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );

        assertEq(weightedNotionalBefore.weightedNotionalPayFixed, 0, "weightedNotionalReceiveFixed should be equal 0");

        assertEq(
            weightedNotionalAfter.weightedNotionalPayFixed,
            newSwapNotional,
            "weightedNotionalReceiveFixed should be equal newSwapNotional"
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

        SpreadTypes.WeightedNotionalMemory memory weightedNotionalBefore = SpreadTypes.WeightedNotionalMemory({
            weightedNotionalPayFixed: 0,
            weightedNotionalReceiveFixed: 1_000_000 * 1e18,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
            weightedNotionalBefore,
            newSwapNotional,
            28 days
        );

        // then
        SpreadTypes.WeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );

        assertTrue(
            weightedNotionalAfter.weightedNotionalReceiveFixed <
                weightedNotionalBefore.weightedNotionalReceiveFixed + newSwapNotional,
            "weightedNotionalReceiveFixed should be less than weightedNotionalBefore + newSwapNotional"
        );
        assertTrue(
            weightedNotionalAfter.weightedNotionalReceiveFixed > newSwapNotional,
            "weightedNotionalReceiveFixed should be greater than newSwapNotional"
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

        SpreadTypes.WeightedNotionalMemory memory weightedNotionalBefore = SpreadTypes.WeightedNotionalMemory({
            weightedNotionalPayFixed: 1_000_000 * 1e18,
            weightedNotionalReceiveFixed: 0,
            lastUpdateTimePayFixed: 0,
            lastUpdateTimeReceiveFixed: block.timestamp,
            storageId: _storageIdIterationItem
        });

        vm.warp(blockTimestamp + 6 days);

        // when
        CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(weightedNotionalBefore, newSwapNotional, 28 days);

        // then
        SpreadTypes.WeightedNotionalMemory memory weightedNotionalAfter = SpreadStorageLibs.getWeightedNotional(
            _storageIdIterationItem
        );
    }

    function testShouldReturnWeightedNotional() public {
        // given
        uint256 timestamp = 120 days;
        vm.warp(timestamp);
        SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days = _getWeightedNotionalMemory(
            1,
            SpreadStorageLibs.StorageId.WeightedNotional28DaysDai
        );
        SpreadTypes.WeightedNotionalMemory memory weightedNotional60Days = _getWeightedNotionalMemory(
            2,
            SpreadStorageLibs.StorageId.WeightedNotional60DaysDai
        );
        SpreadTypes.WeightedNotionalMemory memory weightedNotional90Days = _getWeightedNotionalMemory(
            3,
            SpreadStorageLibs.StorageId.WeightedNotional90DaysDai
        );

        weightedNotional28Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional28Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional60Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimePayFixed = timestamp - 10 days;
        weightedNotional90Days.lastUpdateTimeReceiveFixed = timestamp - 10 days;

        SpreadStorageLibs.saveWeightedNotional(
            SpreadStorageLibs.StorageId.WeightedNotional28DaysDai,
            weightedNotional28Days
        );

        SpreadStorageLibs.saveWeightedNotional(
            SpreadStorageLibs.StorageId.WeightedNotional60DaysDai,
            weightedNotional60Days
        );

        SpreadStorageLibs.saveWeightedNotional(
            SpreadStorageLibs.StorageId.WeightedNotional90DaysDai,
            weightedNotional90Days
        );

        SpreadStorageLibs.StorageId[] memory storageIds = new SpreadStorageLibs.StorageId[](3);
        storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysDai;
        storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional60DaysDai;
        storageIds[2] = SpreadStorageLibs.StorageId.WeightedNotional90DaysDai;

        uint256[] memory maturities = new uint256[](3);
        maturities[0] = 28 days;
        maturities[1] = 60 days;
        maturities[2] = 90 days;

        // when
        (uint256 weightedNotionalPayFixed, uint256 weightedNotionalReceiveFixed) = CalculateWeightedNotionalLibs
            .getWeightedNotional(storageIds, maturities);

        // then

        uint256 weightedNotionalPayFixed28DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional28Days.weightedNotionalPayFixed,
            10 days,
            28 days
        );
        uint256 weightedNotionalPayFixed60DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional60Days.weightedNotionalPayFixed,
            10 days,
            60 days
        );

        uint256 weightedNotionalPayFixed90DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional90Days.weightedNotionalPayFixed,
            10 days,
            90 days
        );
        uint256 weightedNotionalReceiveFixed28DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional28Days.weightedNotionalReceiveFixed,
            10 days,
            28 days
        );
        uint256 weightedNotionalReceiveFixed60DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional60Days.weightedNotionalReceiveFixed,
            10 days,
            60 days
        );

        uint256 weightedNotionalReceiveFixed90DaysResult = CalculateWeightedNotionalLibs.calculateWeightedNotional(
            weightedNotional90Days.weightedNotionalReceiveFixed,
            10 days,
            90 days
        );

        assertTrue(
            weightedNotionalPayFixed <
                weightedNotional28Days.weightedNotionalPayFixed +
                    weightedNotional60Days.weightedNotionalPayFixed +
                    weightedNotional90Days.weightedNotionalPayFixed,
            "weightedNotionalPayFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            weightedNotionalPayFixed,
            weightedNotionalPayFixed28DaysResult +
                weightedNotionalPayFixed60DaysResult +
                weightedNotionalPayFixed90DaysResult,
            "weightedNotionalPayFixed should be equal to weightedNotionalPayFixed28DaysResult + weightedNotionalPayFixed90DaysResult"
        );

        assertTrue(
            weightedNotionalReceiveFixed <
                weightedNotional28Days.weightedNotionalReceiveFixed +
                    weightedNotional60Days.weightedNotionalReceiveFixed +
                    weightedNotional90Days.weightedNotionalReceiveFixed,
            "weightedNotionalReceiveFixed should be less than weightedNotional28Days + weightedNotional90Days"
        );

        assertEq(
            weightedNotionalReceiveFixed,
            weightedNotionalReceiveFixed28DaysResult +
                weightedNotionalReceiveFixed60DaysResult +
                weightedNotionalReceiveFixed90DaysResult,
            "weightedNotionalReceiveFixed should be equal to weightedNotionalReceiveFixed28DaysResult + weightedNotionalReceiveFixed90DaysResult"
        );
    }

    function _getWeightedNotionalMemory(uint256 seed, SpreadStorageLibs.StorageId storageId)
        private
        returns (SpreadTypes.WeightedNotionalMemory memory)
    {
        return
            SpreadTypes.WeightedNotionalMemory({
                weightedNotionalPayFixed: seed * 1e18,
                lastUpdateTimePayFixed: seed * 2000,
                weightedNotionalReceiveFixed: seed * 3e18,
                lastUpdateTimeReceiveFixed: seed * 4000,
                storageId: storageId
            });
    }
}
