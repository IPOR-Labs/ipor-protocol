// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/MockIporWeighted.sol";
import "forge-std/console2.sol";
import "./MockOldIporOracleV2.sol";
import "./MockItfIporOracleV2.sol";

contract IporOracleTest is Test, TestCommons {
    using stdStorage for StdStorage;

    uint32 private _blockTimestamp = 1641701;
    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private  _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    ItfIporOracle private _iporOracle;

    function setUp() public {
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);

        uint64[] memory exponentialMovingAverages = new uint64[](3);
        exponentialMovingAverages[0] = uint64(3e16);
        exponentialMovingAverages[1] = uint64(3e16);
        exponentialMovingAverages[2] = uint64(3e16);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](3);

        exponentialWeightedMovingVariances[0] = uint64(0);
        exponentialWeightedMovingVariances[1] = uint64(0);
        exponentialWeightedMovingVariances[2] = uint64(0);

        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(address(iporOracleImplementation), abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
        _iporOracle = ItfIporOracle(address(iporOracleProxy));

        _iporOracle.addUpdater(address(this));

    }

    function testShouldRemovedAsset() public {
        // given
        bool assetSupportedBefore = _iporOracle.isAssetSupported(address(_daiTestnetToken));
        // when
        vm.expectEmit(true, true, true, true);
        emit IporIndexRemoveAsset(address(_daiTestnetToken));
        _iporOracle.removeAsset(address(_daiTestnetToken));
        // then
        bool assetSupportedAfter = _iporOracle.isAssetSupported(address(_daiTestnetToken));

        assertEq(assetSupportedBefore, true);
        assertEq(assetSupportedAfter, false);
    }

    function testShouldDecayFactorBeLowerThanOrEqual100Percentage() public {
        // given
        uint256 decayFactorZero = _iporOracle.itfGetDecayFactorValue(0);
        uint256 decayFactorOne = _iporOracle.itfGetDecayFactorValue(119780);
        uint256 decayFactorTwo = _iporOracle.itfGetDecayFactorValue(3024001);
        // then
        assertEq(decayFactorZero <= 100e16, true);
        assertEq(decayFactorOne <= 100e16, true);
        assertEq(decayFactorTwo <= 100e16, true);
    }

    function testShouldReturnContractVersion() public {
        // given
        uint256 version = _iporOracle.getVersion();
        // then
        assertEq(version, 3);
    }

    function testShouldPauseSCWhenSenderIsAdmin() public {
        // given
        bool pausedBefore = _iporOracle.paused();
        // when
        _iporOracle.pause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        _iporOracle.pause();
        bool pausedBefore = _iporOracle.paused();
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint256[] memory indexValues = new uint256[](3);
        indexValues[0] = 7e16;
        indexValues[1] = 7e16;
        indexValues[2] = 7e16;

        MockTestnetToken randomStable = new MockTestnetToken("Random Stable", "SandomStable", 100_000_000 * 1e18, uint8(18));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.updateIndex(assets[0], indexValues[1]);

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.updateIndexes(assets, indexValues);

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.addAsset(address(randomStable), 0, 0, 0);

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.removeAsset(address(_daiTestnetToken));

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.updateAndFetchIndex(address(_daiTestnetToken));

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.addUpdater(address(this));

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.removeUpdater(address(this));

        // then
        bool pausedAfter = _iporOracle.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        _blockTimestamp += 60 * 60;
        vm.warp(_blockTimestamp);
        _iporOracle.pause();
        bool pausedBefore = _iporOracle.paused();

        //when
        _iporOracle.getIndex(address(_daiTestnetToken));
        _iporOracle.getAccruedIndex(_blockTimestamp, address(_daiTestnetToken));
        _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        _iporOracle.isAssetSupported(address(_daiTestnetToken));
        _iporOracle.isUpdater(address(this));

        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        bool pausedBefore = _iporOracle.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.pause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _iporOracle.pause();
        bool pausedBefore = _iporOracle.paused();
        // when
        _iporOracle.unpause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _iporOracle.pause();
        bool pausedBefore = _iporOracle.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.unpause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporOracle.owner();
        // when
        _iporOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporOracle.owner();
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.transferOwnership(newOwner);

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporOracle.owner();
        // when
        _iporOracle.transferOwnership(newOwner);
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        _iporOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);
        address ownerBefore = _iporOracle.owner();

        // when
        _iporOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporOracle.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        vm.prank(newOwner);
        _iporOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporOracle.owner();
        // when
        _iporOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporOracle.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHaveRights() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporOracle.owner();
        // when
        _iporOracle.transferOwnership(newOwner);
        _iporOracle.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _iporOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotUpdateIporIndexWhenSenderIsNotAnUpdater() public {
        // given
        (uint256 iporIndexBefore,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), 1000, _blockTimestamp + 60 * 60);
        // then
        (uint256 iporIndexAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, 0);
    }

    function testShouldNotUpdateIporIndexWhenUpdatersWasRemoved() public {
        // given
        _iporOracle.removeUpdater(address(this));
        (uint256 iporIndexBefore,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), 1000, _blockTimestamp + 60 * 60);
        // then
        (uint256 iporIndexAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, 0);
    }

    function testShouldUpdateIporIndexDAI() public {
        // given
        uint256 expectedIndexValue = 5e16;
        (uint256 iporIndexBefore,uint256 ibtPriceBefore,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        _iporOracle.updateIndex(address(_daiTestnetToken), expectedIndexValue);
        // then
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, expectedIndexValue);
        assertEq(ibtPriceBefore, 1e18);
        assertEq(ibtPriceAfter, 1e18);
    }

    function testShouldUpdateIndexes() public {
        // given
        uint256 expectedIndexValue = 7e16;
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);
        uint256[] memory indexValues = new uint256[](3);
        indexValues[0] = expectedIndexValue;
        indexValues[1] = expectedIndexValue;
        indexValues[2] = expectedIndexValue;

        (uint256 iporIndexDaiBefore,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcBefore,,,,) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtBefore,,,,) = _iporOracle.getIndex(address(_usdtTestnetToken));

        // when
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp + 60 * 60);

        // then

        (uint256 iporIndexDaiAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcAfter,,,,) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtAfter,,,,) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexDaiBefore, 0);
        assertEq(iporIndexDaiAfter, expectedIndexValue);
        assertEq(iporIndexUsdcBefore, 0);
        assertEq(iporIndexUsdcAfter, expectedIndexValue);
        assertEq(iporIndexUsdtBefore, 0);
        assertEq(iporIndexUsdtAfter, expectedIndexValue);
    }

    function testShouldNotAddIporIndexUpdaterWhenNotOwner() public {
        // given
        address updater = _getUserAddress(1);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.addUpdater(updater);
        // then
        uint256 isUpdater = _iporOracle.isUpdater(updater);
        assertEq(isUpdater, 0);
    }

    function testShouldRemoveIporIndexUpdater() public {
        // given
        uint256 isUpdaterBefore = _iporOracle.isUpdater(address(this));

        // when
        _iporOracle.removeUpdater(address(this));

        // then
        uint256 isUpdaterAfter = _iporOracle.isUpdater(address(this));


        assertEq(isUpdaterBefore, 1);
        assertEq(isUpdaterAfter, 0);
    }

    function testShouldNotBeAbleToUpdateWhenUpdaterRemoved() public {
        // given
        _iporOracle.removeUpdater(address(this));
        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        _iporOracle.updateIndex(address(_daiTestnetToken), 5e16);
        // then
        (uint256 iporIndexAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(iporIndexAfter, 0);
    }

    function testShouldNotRemoveIporIndexUpdaterWhenNotOwner() public {
        // given
        address updater = address(this);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOracle.removeUpdater(updater);
        // then
        uint256 isUpdater = _iporOracle.isUpdater(updater);
        assertEq(isUpdater, 1);
    }

    function testShouldUpdateExistingIporIndex() public {
        // given
        uint256 expectedIndexValueOne = 123e15;
        uint256 expectedIndexValueTwo = 321e15;

        // when
        _iporOracle.updateIndex(address(_daiTestnetToken), expectedIndexValueOne);
        (uint256 iporIndexBefore,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        _iporOracle.updateIndex(address(_daiTestnetToken), expectedIndexValueTwo);

        // then
        (uint256 iporIndexAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, expectedIndexValueOne);
        assertEq(iporIndexAfter, expectedIndexValueTwo);
    }

    function testShouldCalculateInitialInterestBearingTokenPrice() public {
        // given
        uint256 iporIndexValue = 5e16;
        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), iporIndexValue, _blockTimestamp + 60 * 60);
        // then
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexAfter, iporIndexValue);
        assertEq(ibtPriceAfter, 1e18);
    }

    function testShouldCalculateNextInterestBearingTokenPriceOneYearPeriod() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 51e15;
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueOne, updateDate);
        updateDate += 365 * 24 * 60 * 60;

        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueTwo, updateDate);

        // then
        uint256 expectedIbtPrice = 105e16;
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexAfter, indexValueTwo);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }

    function testShouldCalculateNextInterestBearingTokenPriceOneMonthPeriod() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 51e15;
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueOne, updateDate);
        updateDate += 30 * 24 * 60 * 60;

        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueTwo, updateDate);

        // then
        uint256 expectedIbtPrice = 1004109589041095890;
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexAfter, indexValueTwo);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }

    function testShouldCalculateDifferentInterestBearingTokenPriceOneSecondPeriodSameIporIndexValue6DecimalsAsset() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 5e16;
        _iporOracle.itfUpdateIndex(address(_usdcTestnetToken), indexValueOne, updateDate);
        console2.log("updateDate ", updateDate);
        updateDate++;
        console2.log("updateDate+", updateDate);
        (uint256 iporIndexBefore,uint256 ibtPriceBefore,,,) = _iporOracle.getIndex(address(_usdcTestnetToken));
        // when
        _iporOracle.itfUpdateIndex(address(_usdcTestnetToken), indexValueTwo, updateDate);

        // then
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_usdcTestnetToken));

        assertEq(iporIndexBefore, indexValueOne);
        assertEq(iporIndexAfter, indexValueTwo);

        assertEq(iporIndexAfter, iporIndexBefore);

        assertEq(ibtPriceBefore != ibtPriceAfter, true);
    }

    function testShouldCalculateDifferentInterestBearingTokenPriceOneSecondPeriodSameIporIndexValue18DecimalsAsset() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 5e16;
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueOne, updateDate);
        updateDate++;
        (uint256 iporIndexBefore,uint256 ibtPriceBefore,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueTwo, updateDate);

        // then
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, indexValueOne);
        assertEq(iporIndexAfter, indexValueTwo);

        assertEq(iporIndexAfter, iporIndexBefore);

        assertEq(ibtPriceBefore != ibtPriceAfter, true);
    }

    function testShouldCalculateNextAfterNextInterestBearingTokenPriceHalfYearAndThreeMonthsSnapshots() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 6e16;
        uint256 iporIndexThirdValue = 7e16;
        uint256 expectedIbtPrice = 104e16;
        _iporOracle.itfUpdateIndex(address(_usdtTestnetToken), indexValueOne, updateDate);
        updateDate += 365 * 24 * 60 * 60 / 2;
        _iporOracle.itfUpdateIndex(address(_usdtTestnetToken), indexValueTwo, updateDate);
        updateDate += 365 * 24 * 60 * 60 / 4;

        // when
        _iporOracle.itfUpdateIndex(address(_usdtTestnetToken), iporIndexThirdValue, updateDate);

        // then
        (uint256 iporIndexAfter,uint256 ibtPriceAfter,,,) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexAfter, iporIndexThirdValue);
        assertEq(ibtPriceAfter, expectedIbtPrice);

    }

    function testShouldNotUpdateIporIndexWhenWrongInputArrays() public {
        // given
        address[] memory assets = new address[](2);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);

        uint256[] memory indexValues = new uint256[](1);
        indexValues[0] = 7e16;

        // when
        vm.expectRevert(abi.encodePacked(IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH));
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp + 60 * 60);
    }

    function testShouldNotUpdateIporIndexWhenAssetNotSupported() public {
        // given
        MockTestnetToken notSupportedAsset = new MockTestnetToken("Not supported", "Not", 100_000_000 * 1e18, uint8(18));
        address[] memory assets = new address[](1);
        assets[0] = address(notSupportedAsset);

        uint256[] memory indexValues = new uint256[](1);
        indexValues[0] = 7e16;

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.ASSET_NOT_SUPPORTED));
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp + 60 * 60);
    }

    function testShouldNotUpdateIporIndexWhenAccrueTimestampLowerThanCurrentIporIndexTimestamp() public {
        // given
        address[] memory assets = new address[](1);
        assets[0] = address(_daiTestnetToken);

        uint256[] memory indexValues = new uint256[](1);
        indexValues[0] = 7e16;
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp);
        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP));
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp - 1);
    }

    function testShouldUpdateIporIndexWhenCorrectInputArrays() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint256[] memory indexValues = new uint256[](3);
        indexValues[0] = 8e16;
        indexValues[1] = 7e16;
        indexValues[2] = 6e16;

        // when
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp + 60 * 60);

        // then
        (uint256 iporIndexDaiAfter,,,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcAfter,,,,) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtAfter,,,,) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexDaiAfter, indexValues[0]);
        assertEq(iporIndexUsdcAfter, indexValues[1]);
        assertEq(iporIndexUsdtAfter, indexValues[2]);
    }

    function testShouldCalculateInitialExponentialMovingAverageSimpleCase1() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint256[] memory indexValues = new uint256[](3);
        indexValues[0] = 7e16;
        indexValues[1] = 7e16;
        indexValues[2] = 7e16;

        uint256 expectedExpoMovingAverage = 3e16;
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp);

        // when
        (,,uint256 expoMovingAverage,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        // then
        assertEq(expoMovingAverage, expectedExpoMovingAverage);
    }

    function testShouldCalculateInitialExponentialMovingAverageSimpleCase2() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint256[] memory indexValues = new uint256[](3);
        indexValues[0] = 7e16;
        indexValues[1] = 7e16;
        indexValues[2] = 7e16;

        uint256 expectedExpoMovingAverage = 7e16;
        _blockTimestamp += 25 * 24 * 60 * 60;
        _iporOracle.itfUpdateIndexes(assets, indexValues, _blockTimestamp);

        // when
        (,,uint256 expoMovingAverage,,) = _iporOracle.getIndex(address(_daiTestnetToken));

        // then
        assertEq(expoMovingAverage, expectedExpoMovingAverage);
    }

    function testShouldCalculateInitialExponentialMovingAverageWhen2xIporIndexUpdates18decimals() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint256[] memory firstIndexValues = new uint256[](3);
        firstIndexValues[0] = 7e16;
        firstIndexValues[1] = 7e16;
        firstIndexValues[2] = 7e16;

        uint256[] memory secondIndexValues = new uint256[](3);
        secondIndexValues[0] = 50e16;
        secondIndexValues[1] = 50e16;
        secondIndexValues[2] = 50e16;
        uint256 expectedExpoMovingAverage = 39618017140823040;

        // when

        _iporOracle.itfUpdateIndexes(assets, firstIndexValues, _blockTimestamp + 24 * 60 * 60);
        _iporOracle.itfUpdateIndexes(assets, secondIndexValues, _blockTimestamp + 24 * 60 * 60);

        // then
        (,,uint256 expoMovingAverage,,) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(expoMovingAverage, expectedExpoMovingAverage);
    }

    function testShouldCalculateInitialExponentialMovingAverageWhen2xIporIndexUpdates6decimals() public {
        // given
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(_usdcTestnetToken);
        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(_blockTimestamp);
        uint64[] memory exponentialMovingAverages = new uint64[](1);
        exponentialMovingAverages[0] = uint64(70000);
        uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);
        exponentialWeightedMovingVariances[0] = uint64(0);
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(address(iporOracleImplementation), abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
        _iporOracle = ItfIporOracle(address(iporOracleProxy));
        _iporOracle.addUpdater(address(this));


        uint256[] memory firstIndexValues = new uint256[](1);
        firstIndexValues[0] = 70000;
        uint256[] memory secondIndexValues = new uint256[](1);
        secondIndexValues[0] = 500000;
        uint256 expectedExpoMovingAverage = 74308;


        // when
        _iporOracle.itfUpdateIndexes(assets, firstIndexValues, _blockTimestamp);
        _iporOracle.itfUpdateIndexes(assets, secondIndexValues, _blockTimestamp + 60 * 60);

        // then
        (,,uint256 expoMovingAverage,,) = _iporOracle.getIndex(address(_usdcTestnetToken));
        assertEq(expoMovingAverage, expectedExpoMovingAverage);
    }

    function testShouldNotSendEthToIporOracle() public payable {
        // given
        // when
        // then
        vm.expectRevert(abi.encodePacked("Transaction reverted: function selector was not recognized and there's no fallback nor receive function"));
        (bool status,) = address(_iporOracle).call{value : msg.value}("");
        assertTrue(!status);
    }


    //   tests for updateAndFetchIndex

    function testShouldNotBeAbleToUpdateWhenAssetNotSupported() public {
        // given
        MockTestnetToken notSupportedAsset = new MockTestnetToken("Not supported", "Not", 100_000_000 * 1e18, uint8(18));

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.ASSET_NOT_SUPPORTED));
        _iporOracle.updateAndFetchIndex(address(notSupportedAsset));

        // then
    }

    function testShouldNotBeAbleToUpdateWhenIporAlgorithmNotSetup() public {
        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.ALGORITHM_ADDRESS_NOT_SET));
        _iporOracle.updateAndFetchIndex(address(_daiTestnetToken));
    }

    function testShouldFetchNewIporIndexFromAlgorithmContract() public {
        // given
        MockIporWeighted algorithmImplementation = new MockIporWeighted();
        ERC1967Proxy algorithmProxy = new ERC1967Proxy(address(algorithmImplementation), abi.encodeWithSignature("initialize(address)", address(_iporOracle)));
        _iporOracle.setAlgorithmAddress(address(algorithmProxy));
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), 7e16, _blockTimestamp);
        (uint256 indexValueBefore, , , ,) = _iporOracle.getIndex(address(_daiTestnetToken));
        _blockTimestamp += 24 * 60 * 60;
        vm.warp(_blockTimestamp);

        // when
        (uint256 indexValueFetch, , , ,) = _iporOracle.updateAndFetchIndex(address(_daiTestnetToken));
        (uint256 indexValueAfter, , , ,) = _iporOracle.getIndex(address(_daiTestnetToken));

        // then
        assertEq(indexValueBefore, 7e16);
        assertEq(indexValueFetch != 7e16, true);
        assertEq(indexValueFetch, indexValueAfter);
    }

    function testShouldUpdateImplementationOnProxy() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);

        uint64[] memory exponentialMovingAverages = new uint64[](3);
        exponentialMovingAverages[0] = uint64(3e16);
        exponentialMovingAverages[1] = uint64(3e16);
        exponentialMovingAverages[2] = uint64(3e16);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](3);

        exponentialWeightedMovingVariances[0] = uint64(0);
        exponentialWeightedMovingVariances[1] = uint64(0);
        exponentialWeightedMovingVariances[2] = uint64(0);

        uint256[] memory firstIndexValues = new uint256[](3);
        firstIndexValues[0] = 7e16;
        firstIndexValues[1] = 7e16;
        firstIndexValues[2] = 7e16;

        MockItfIporOracleV2 oldIporOracleImplementation = new MockItfIporOracleV2();
        ItfIporOracle newIporOracleImplementation = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(address(oldIporOracleImplementation), abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
        address proxyAddress = address(iporOracleProxy);
        MockItfIporOracleV2(proxyAddress).addUpdater(address(this));



        MockIporWeighted algorithmImplementation = new MockIporWeighted();
        ERC1967Proxy algorithmProxy = new ERC1967Proxy(address(algorithmImplementation), abi.encodeWithSignature("initialize(address)", address(_iporOracle)));

        MockItfIporOracleV2(proxyAddress).itfUpdateIndexes(assets, firstIndexValues, _blockTimestamp);

        (uint256 indexValueDaiBefore, , , ,) = MockOldIporOracleV2(proxyAddress).getIndex(address(_daiTestnetToken));
        (uint256 indexValueUsdcBefore, , , ,) = MockOldIporOracleV2(proxyAddress).getIndex(address(_usdcTestnetToken));
        (uint256 indexValueUsdtBefore, , , ,) = MockOldIporOracleV2(proxyAddress).getIndex(address(_usdtTestnetToken));

        // when
        MockOldIporOracleV2(proxyAddress).upgradeTo(address(newIporOracleImplementation));
        ItfIporOracle(proxyAddress).setAlgorithmAddress(address(algorithmProxy));

        (uint256 indexValueDaiAfterUpdateImplementation, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_daiTestnetToken));
        (uint256 indexValueUsdcAfterUpdateImplementation, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_usdcTestnetToken));
        (uint256 indexValueUsdtAfterUpdateImplementation, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_usdtTestnetToken));

        ItfIporOracle(proxyAddress).updateAndFetchIndex(address(_daiTestnetToken));
        ItfIporOracle(proxyAddress).updateAndFetchIndex(address(_usdcTestnetToken));
        ItfIporOracle(proxyAddress).updateAndFetchIndex(address(_usdtTestnetToken));

        // then

        (uint256 indexValueDaiAfterUpdateIndex, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_daiTestnetToken));
        (uint256 indexValueUsdcAfterUpdateIndex, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_usdcTestnetToken));
        (uint256 indexValueUsdtAfterUpdateIndex, , , ,) = ItfIporOracle(proxyAddress).getIndex(address(_usdtTestnetToken));

        assertEq(indexValueDaiBefore, 7e16);
        assertEq(indexValueUsdcBefore, 7e16);
        assertEq(indexValueUsdtBefore, 7e16);
        assertEq(indexValueDaiAfterUpdateImplementation, indexValueDaiBefore);
        assertEq(indexValueUsdcAfterUpdateImplementation, indexValueUsdcBefore);
        assertEq(indexValueUsdtAfterUpdateImplementation, indexValueUsdtBefore);
        assertTrue(indexValueDaiAfterUpdateIndex != indexValueDaiAfterUpdateImplementation);
        assertTrue(indexValueUsdcAfterUpdateIndex != indexValueUsdcAfterUpdateImplementation);
        assertTrue(indexValueUsdtAfterUpdateIndex != indexValueUsdtAfterUpdateImplementation);


    }



    /// @notice event emitted when asset is removed by Owner from list of assets supported in IPOR Protocol.
    /// @param asset asset address
    event IporIndexRemoveAsset(address asset);
}

