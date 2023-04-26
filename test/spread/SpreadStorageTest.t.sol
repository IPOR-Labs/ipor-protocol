// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../contracts/amm/spread/SpreadTypes.sol";
import "../TestCommons.sol";
import "./MockSpreadStorage.sol";


contract SpreadRouterTest is TestCommons {
    using SafeCast for uint256;
    MockSpreadStorage internal _storage;
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

    function setUp() public {
        _storage = new MockSpreadStorage();
    }

    function testShouldSaveWeightedNotional(uint256 seed) public _parameterizedStorageId {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    function testShouldSaveWeightedNotionalWhenWeightedNotionalPayFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.weightedNotionalPayFixed = uint256(type(uint96).max) * 1e18;

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    function testShouldRevertOnSaveWhenWeightedNotionalPayFixedIsBiggerThanMaxUint96(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.weightedNotionalPayFixed = uint256(type(uint96).max) * 1e18 + 1e18;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 96 bits");
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenWeightedNotionalReceiveFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.weightedNotionalReceiveFixed = uint256(type(uint96).max) * 1e18;

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );
        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    function testShouldRevertOnSaveWhenWeightedNotionalReceiveFixedIsBiggerThanMaxUint96(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.weightedNotionalReceiveFixed = uint256(type(uint96).max) * 1e18 + 1e18;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 96 bits");
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenLastUpdateTimePayFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.lastUpdateTimePayFixed = uint256(type(uint32).max);

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    function testShouldRevertOnSaveWeightedNotionalWhenLastUpdateTimePayFixedIsBiggerThenMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.lastUpdateTimePayFixed = uint256(type(uint32).max) + 1;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 32 bits");
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenLastUpdateTimeReceiveFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.lastUpdateTimeReceiveFixed = uint256(type(uint32).max);

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    function testShouldRevertOnSaveWeightedNotionalWhenLastUpdateTimeReceiveFixedIsBiggerThanMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days = _getWeightedNotional28DaysMemory(seed);
        weightedNotional28Days.lastUpdateTimeReceiveFixed = uint256(type(uint32).max) +1;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 32 bits");
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenAllMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.WeightedNotional28DaysMemory memory weightedNotional28Days = SpreadTypes
            .WeightedNotional28DaysMemory({
                weightedNotionalPayFixed: uint256(type(uint96).max) * 1e18,
                lastUpdateTimePayFixed: uint256(type(uint32).max),
                weightedNotionalReceiveFixed: uint256(type(uint96).max) * 1e18,
                lastUpdateTimeReceiveFixed: uint256(type(uint32).max)
            });

        // when
        _storage.saveWeightedNotional28Days(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result = _storage.getWeightedNotional28Days(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    // Save for 6 different object and read them from storage
    function testSaveAndReadAllSlots() public {
        // given
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days1 = _getWeightedNotional28DaysMemory(1);
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days2 = _getWeightedNotional28DaysMemory(2);
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days3 = _getWeightedNotional28DaysMemory(3);
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days4 = _getWeightedNotional28DaysMemory(4);
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days5 = _getWeightedNotional28DaysMemory(5);
        SpreadTypes.WeightedNotional28DaysMemory
            memory weightedNotional28Days6 = _getWeightedNotional28DaysMemory(6);

        // when
        _storage.saveWeightedNotional28Days(_storageIdEnums[0], weightedNotional28Days1);
        _storage.saveWeightedNotional28Days(_storageIdEnums[1], weightedNotional28Days2);
        _storage.saveWeightedNotional28Days(_storageIdEnums[2], weightedNotional28Days3);
        _storage.saveWeightedNotional28Days(_storageIdEnums[3], weightedNotional28Days4);
        _storage.saveWeightedNotional28Days(_storageIdEnums[4], weightedNotional28Days5);
        _storage.saveWeightedNotional28Days(_storageIdEnums[5], weightedNotional28Days6);

        // then
        SpreadTypes.WeightedNotional28DaysMemory memory result1 = _storage
            .getWeightedNotional28Days(_storageIdEnums[0]);
        SpreadTypes.WeightedNotional28DaysMemory memory result2 = _storage
            .getWeightedNotional28Days(_storageIdEnums[1]);
        SpreadTypes.WeightedNotional28DaysMemory memory result3 = _storage
            .getWeightedNotional28Days(_storageIdEnums[2]);
        SpreadTypes.WeightedNotional28DaysMemory memory result4 = _storage
            .getWeightedNotional28Days(_storageIdEnums[3]);
        SpreadTypes.WeightedNotional28DaysMemory memory result5 = _storage
            .getWeightedNotional28Days(_storageIdEnums[4]);
        SpreadTypes.WeightedNotional28DaysMemory memory result6 = _storage
            .getWeightedNotional28Days(_storageIdEnums[5]);

        _assertWeightedNotional(weightedNotional28Days1, result1, _storageIdEnums[0]);
        _assertWeightedNotional(weightedNotional28Days2, result2, _storageIdEnums[1]);
        _assertWeightedNotional(weightedNotional28Days3, result3, _storageIdEnums[2]);
        _assertWeightedNotional(weightedNotional28Days4, result4, _storageIdEnums[3]);
        _assertWeightedNotional(weightedNotional28Days5, result5, _storageIdEnums[4]);
        _assertWeightedNotional(weightedNotional28Days6, result6, _storageIdEnums[5]);
    }

    function _getWeightedNotional28DaysMemory(uint256 seed)
        private
        returns (SpreadTypes.WeightedNotional28DaysMemory memory)
    {
        return
            SpreadTypes.WeightedNotional28DaysMemory({
                weightedNotionalPayFixed: seed * 1e18,
                lastUpdateTimePayFixed: seed * 2000,
                weightedNotionalReceiveFixed: seed * 3e18,
                lastUpdateTimeReceiveFixed: seed * 4000
            });
    }

    function _assertWeightedNotional(
        SpreadTypes.WeightedNotional28DaysMemory memory expected,
        SpreadTypes.WeightedNotional28DaysMemory memory actual,
        SpreadStorageLibs.StorageId storageId
    ) private {
        assertEq(
            expected.weightedNotionalPayFixed,
            actual.weightedNotionalPayFixed,
            string.concat(
                "weightedNotionalPayFixed: expected ",
                Strings.toString(expected.weightedNotionalPayFixed),
                " but got ",
                Strings.toString(actual.weightedNotionalPayFixed),
                " for storageId ",
                Strings.toString(uint256(storageId))
            )
        );
        assertEq(
            expected.lastUpdateTimePayFixed,
            actual.lastUpdateTimePayFixed,
            string.concat(
                "lastUpdateTimePayFixed: expected ",
                Strings.toString(expected.lastUpdateTimePayFixed),
                " but got ",
                Strings.toString(actual.lastUpdateTimePayFixed),
                " for storageId ",
                Strings.toString(uint256(storageId))
            )
        );
        assertEq(
            expected.weightedNotionalReceiveFixed,
            actual.weightedNotionalReceiveFixed,
            string.concat(
                "weightedNotionalReceiveFixed: expected ",
                Strings.toString(expected.weightedNotionalReceiveFixed),
                " but got ",
                Strings.toString(actual.weightedNotionalReceiveFixed),
                " for storageId ",
                Strings.toString(uint256(storageId))
            )
        );
        assertEq(
            expected.lastUpdateTimeReceiveFixed,
            actual.lastUpdateTimeReceiveFixed,
            string.concat(
                "lastUpdateTimeReceiveFixed: expected ",
                Strings.toString(expected.lastUpdateTimeReceiveFixed),
                " but got ",
                Strings.toString(actual.lastUpdateTimeReceiveFixed),
                " for storageId ",
                Strings.toString(uint256(storageId))
            )
        );
    }
}
