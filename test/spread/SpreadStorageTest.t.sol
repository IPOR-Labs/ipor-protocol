// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/amm/spread/SpreadTypes.sol";
import "test/TestCommons.sol";
import "./MockSpreadStorage.sol";


contract SpreadRouterTest is TestCommons {
    using SafeCast for uint256;
    MockSpreadStorage internal _storage;
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

    function setUp() public {
        _storage = new MockSpreadStorage();
    }

    function testShouldSaveWeightedNotional(uint256 seed) public _parameterizedStorageId {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.timeWeightedNotionalPayFixed = uint256(type(uint96).max) * 1e18;

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.timeWeightedNotionalPayFixed = uint256(type(uint96).max) * 1e18 + 1e18;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 96 bits");
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenWeightedNotionalReceiveFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.timeWeightedNotionalReceiveFixed = uint256(type(uint96).max) * 1e18;

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.timeWeightedNotionalReceiveFixed = uint256(type(uint96).max) * 1e18 + 1e18;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 96 bits");
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenLastUpdateTimePayFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.lastUpdateTimePayFixed = uint256(type(uint32).max);

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.lastUpdateTimePayFixed = uint256(type(uint32).max) + 1;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 32 bits");
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenLastUpdateTimeReceiveFixedHasMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.lastUpdateTimeReceiveFixed = uint256(type(uint32).max);

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
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
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days = _getWeightedNotionalMemory(seed);
        weightedNotional28Days.lastUpdateTimeReceiveFixed = uint256(type(uint32).max) +1;

        // when
        vm.expectRevert("SafeCast: value doesn't fit in 32 bits");
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

    }

    function testShouldSaveWeightedNotionalWhenAllMaxValue(uint256 seed)
        public
        _parameterizedStorageId
    {
        vm.assume(seed < 1000);
        // given
        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days = SpreadTypes
            .TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: uint256(type(uint96).max) * 1e18,
                lastUpdateTimePayFixed: uint256(type(uint32).max),
                timeWeightedNotionalReceiveFixed: uint256(type(uint96).max) * 1e18,
                lastUpdateTimeReceiveFixed: uint256(type(uint32).max),
                storageId: _storageIdIterationItem
            });

        // when
        _storage.saveWeightedNotional(_storageIdIterationItem, weightedNotional28Days);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result = _storage.getWeightedNotional(
            _storageIdIterationItem
        );

        _assertWeightedNotional(weightedNotional28Days, result, _storageIdIterationItem);
    }

    // Save for 6 different object and read them from storage
    function testSaveAndReadAllSlots() public {
        // given
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days1 = _getWeightedNotionalMemory(1);
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days2 = _getWeightedNotionalMemory(2);
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days3 = _getWeightedNotionalMemory(3);
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days4 = _getWeightedNotionalMemory(4);
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days5 = _getWeightedNotionalMemory(5);
        SpreadTypes.TimeWeightedNotionalMemory
            memory weightedNotional28Days6 = _getWeightedNotionalMemory(6);

        // when
        _storage.saveWeightedNotional(_storageIdEnums[0], weightedNotional28Days1);
        _storage.saveWeightedNotional(_storageIdEnums[1], weightedNotional28Days2);
        _storage.saveWeightedNotional(_storageIdEnums[2], weightedNotional28Days3);
        _storage.saveWeightedNotional(_storageIdEnums[3], weightedNotional28Days4);
        _storage.saveWeightedNotional(_storageIdEnums[4], weightedNotional28Days5);
        _storage.saveWeightedNotional(_storageIdEnums[5], weightedNotional28Days6);

        // then
        SpreadTypes.TimeWeightedNotionalMemory memory result1 = _storage
            .getWeightedNotional(_storageIdEnums[0]);
        SpreadTypes.TimeWeightedNotionalMemory memory result2 = _storage
            .getWeightedNotional(_storageIdEnums[1]);
        SpreadTypes.TimeWeightedNotionalMemory memory result3 = _storage
            .getWeightedNotional(_storageIdEnums[2]);
        SpreadTypes.TimeWeightedNotionalMemory memory result4 = _storage
            .getWeightedNotional(_storageIdEnums[3]);
        SpreadTypes.TimeWeightedNotionalMemory memory result5 = _storage
            .getWeightedNotional(_storageIdEnums[4]);
        SpreadTypes.TimeWeightedNotionalMemory memory result6 = _storage
            .getWeightedNotional(_storageIdEnums[5]);

        _assertWeightedNotional(weightedNotional28Days1, result1, _storageIdEnums[0]);
        _assertWeightedNotional(weightedNotional28Days2, result2, _storageIdEnums[1]);
        _assertWeightedNotional(weightedNotional28Days3, result3, _storageIdEnums[2]);
        _assertWeightedNotional(weightedNotional28Days4, result4, _storageIdEnums[3]);
        _assertWeightedNotional(weightedNotional28Days5, result5, _storageIdEnums[4]);
        _assertWeightedNotional(weightedNotional28Days6, result6, _storageIdEnums[5]);
    }

    function _getWeightedNotionalMemory(uint256 seed)
        private
        returns (SpreadTypes.TimeWeightedNotionalMemory memory)
    {
        return
            SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: seed * 1e18,
                lastUpdateTimePayFixed: seed * 2000,
                timeWeightedNotionalReceiveFixed: seed * 3e18,
                lastUpdateTimeReceiveFixed: seed * 4000,
                storageId: _storageIdIterationItem
            });
    }

    function _assertWeightedNotional(
        SpreadTypes.TimeWeightedNotionalMemory memory expected,
        SpreadTypes.TimeWeightedNotionalMemory memory actual,
        SpreadStorageLibs.StorageId storageId
    ) private {
        assertEq(
            expected.timeWeightedNotionalPayFixed,
            actual.timeWeightedNotionalPayFixed,
            string.concat(
                "timeWeightedNotionalPayFixed: expected ",
                Strings.toString(expected.timeWeightedNotionalPayFixed),
                " but got ",
                Strings.toString(actual.timeWeightedNotionalPayFixed),
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
            expected.timeWeightedNotionalReceiveFixed,
            actual.timeWeightedNotionalReceiveFixed,
            string.concat(
                "timeWeightedNotionalReceiveFixed: expected ",
                Strings.toString(expected.timeWeightedNotionalReceiveFixed),
                " but got ",
                Strings.toString(actual.timeWeightedNotionalReceiveFixed),
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
