// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../mocks/tokens/MockTestnetToken.sol";

contract IporOracleTest is TestCommons {
    using stdStorage for StdStorage;

    event IporIndexRemoveAsset(address asset);

    uint32 private _blockTimestamp = 1641701;

    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    MockStETH private _stEthTestnetToken;

    IporOracle private _iporOracle;

    function setUp() public {
        _admin = address(this);
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        _stEthTestnetToken = new MockStETH("Mocked stETH", "stETH", 100_000_000 * 1e18, uint8(18));

        IporOracle iporOracleImplementation = new IporOracle(
            address(_usdcTestnetToken),
            1e18,
            address(_usdtTestnetToken),
            1e18,
            address(_daiTestnetToken),
            1e18,
            address(_stEthTestnetToken)
        );

        address[] memory assets = new address[](4);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);
        assets[3] = address(_stEthTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](4);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);
        updateTimestamps[3] = uint32(_blockTimestamp);

        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature("initialize(address[],uint32[])", assets, updateTimestamps)
        );
        _iporOracle = IporOracle(address(iporOracleProxy));

        _iporOracle.addUpdater(address(this));
    }

    function testShouldCalculateIbtPriceForFixedRate() public {
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, 1e18);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));

        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 1 days),
            1000082195158658879
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 7 days),
            1000575508006975985
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 30 days),
            1002468795894779595
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 180 days),
            1014904501167913392
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 365 days),
            1030454533953516856
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 730 days),
            1061836546545359623
        );
    }

    function testShouldCalculateIbtPriceForFixedRateAndPublicationsInOneDayInterval() public {
        // given
        vm.warp(_blockTimestamp);
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, 1e18);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));

        // when
        for (uint256 i; i < 365; ++i) {
            vm.warp(block.timestamp + 1 days);
            _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));
        }

        // then
        assertEq(_iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp), 1030454533953516856);
    }

    function testShouldCalculateIbtPriceForFixedRateAndPublicationsInSevenDaysInterval() public {
        // given
        vm.warp(_blockTimestamp);
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, 1e18);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));

        // when
        for (uint256 i; i < 52; ++i) {
            vm.warp(block.timestamp + 7 days);
            _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));
        }
        vm.warp(block.timestamp + 1 days);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 3e16));

        // then
        assertEq(_iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp), 1030454533953516856);
    }

    function testShouldCalculateDifferentInterestBearingTokenPriceOneSecondPeriodSameIporIndexValue18DecimalsAsset()
        public
    {
        // given
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 5e16;

        vm.warp(_blockTimestamp + 60 * 60);

        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), indexValueOne));

        vm.warp(_blockTimestamp + 60 * 60 + 1);

        (uint256 iporIndexBefore, uint256 ibtPriceBefore, ) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), indexValueTwo));

        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, indexValueOne);
        assertEq(iporIndexAfter, indexValueTwo);

        assertEq(iporIndexAfter, iporIndexBefore);

        assertEq(ibtPriceBefore != ibtPriceAfter, true);
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

    function testShouldReturnContractVersion() public {
        // given
        uint256 version = _iporOracle.getVersion();
        // then
        assertEq(version, 2_001);
    }

    function testShouldPauseSCWhenSenderIsPauseGuardian() public {
        // given
        bool pausedBefore = _iporOracle.paused();
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporOracle.addPauseGuardians(pauseGuardians);

        // when
        _iporOracle.pause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporOracle.addPauseGuardians(pauseGuardians);
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

        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.updateIndexes(getIndexToUpdate(assets[0], indexValues[1]));

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.addAsset(address(randomStable), 0);

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporOracle.removeAsset(address(_daiTestnetToken));

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

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporOracle.addPauseGuardians(pauseGuardians);

        _iporOracle.pause();

        bool pausedBefore = _iporOracle.paused();

        //when
        _iporOracle.getVersion();
        _iporOracle.getIndex(address(_daiTestnetToken));
        _iporOracle.getAccruedIndex(_blockTimestamp, address(_daiTestnetToken));
        _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        _iporOracle.isUpdater(address(this));
        _iporOracle.isAssetSupported(address(_daiTestnetToken));
        _iporOracle.isPauseGuardian(address(this));

        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnPauseGuardian() public {
        // given
        bool pausedBefore = _iporOracle.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        _iporOracle.pause();
        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporOracle.addPauseGuardians(pauseGuardians);
        _iporOracle.pause();
        bool pausedBefore = _iporOracle.paused();
        _iporOracle.removePauseGuardians(pauseGuardians);

        // when
        _iporOracle.unpause();

        // then
        bool pausedAfter = _iporOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporOracle.addPauseGuardians(pauseGuardians);
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
        (uint256 iporIndexBefore, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        vm.warp(_blockTimestamp + 60 * 60);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 1000));
        // then
        (uint256 iporIndexAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, 0);
    }

    function testShouldNotUpdateIporIndexWhenUpdatersWasRemoved() public {
        // given
        _iporOracle.removeUpdater(address(this));
        (uint256 iporIndexBefore, , ) = _iporOracle.getIndex(address(_daiTestnetToken));

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        vm.warp(_blockTimestamp + 60 * 60);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 1000));

        // then
        (uint256 iporIndexAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, 0);
    }

    function testShouldUpdateIporIndexDAI() public {
        // given
        uint256 expectedIndexValue = 5e16;
        (uint256 iporIndexBefore, uint256 ibtPriceBefore, ) = _iporOracle.getIndex(address(_daiTestnetToken));
        // when
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), expectedIndexValue));
        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, 0);
        assertEq(iporIndexAfter, expectedIndexValue);
        assertEq(ibtPriceBefore, 1e18);
        assertEq(ibtPriceAfter, 1e18);
    }

    function testShouldUpdateIndexes() public {
        // given
        uint256 expectedIndexValue = 7e16;
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](3);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: address(_daiTestnetToken),
            indexValue: expectedIndexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        updateIndexParams[1] = IIporOracle.UpdateIndexParams({
            asset: address(_usdcTestnetToken),
            indexValue: expectedIndexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        updateIndexParams[2] = IIporOracle.UpdateIndexParams({
            asset: address(_usdtTestnetToken),
            indexValue: expectedIndexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });



        (uint256 iporIndexDaiBefore, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcBefore, , ) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtBefore, , ) = _iporOracle.getIndex(address(_usdtTestnetToken));

        // when
        vm.warp(_blockTimestamp + 60 * 60);
        _iporOracle.updateIndexes(updateIndexParams);

        // then

        (uint256 iporIndexDaiAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcAfter, , ) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtAfter, , ) = _iporOracle.getIndex(address(_usdtTestnetToken));

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
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 5e16));
        // then
        (uint256 iporIndexAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
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
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), expectedIndexValueOne));
        (uint256 iporIndexBefore, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), expectedIndexValueTwo));

        // then
        (uint256 iporIndexAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));

        assertEq(iporIndexBefore, expectedIndexValueOne);
        assertEq(iporIndexAfter, expectedIndexValueTwo);
    }


    function testShouldNotUpdateIporIndexWhenAccrueTimestampLowerThanCurrentIporIndexTimestamp() public {
        // given

        vm.warp(block.timestamp + 100);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 7e16));
        vm.warp(block.timestamp - 1);

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP));
        _iporOracle.updateIndexes(getIndexToUpdate(address(_daiTestnetToken), 7e16));
    }

    function testShouldUpdateIporIndexWhenCorrectInputArrays() public {
        // given
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](3);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: address(_daiTestnetToken),
            indexValue: 8e16,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        updateIndexParams[1] = IIporOracle.UpdateIndexParams({
            asset: address(_usdcTestnetToken),
            indexValue: 7e16,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        updateIndexParams[2] = IIporOracle.UpdateIndexParams({
            asset: address(_usdtTestnetToken),
            indexValue: 6e16,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });

        vm.warp(_blockTimestamp + 60 * 60);
        // when
        _iporOracle.updateIndexes(updateIndexParams);

        // then
        (uint256 iporIndexDaiAfter, , ) = _iporOracle.getIndex(address(_daiTestnetToken));
        (uint256 iporIndexUsdcAfter, , ) = _iporOracle.getIndex(address(_usdcTestnetToken));
        (uint256 iporIndexUsdtAfter, , ) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexDaiAfter, updateIndexParams[0].indexValue);
        assertEq(iporIndexUsdcAfter, updateIndexParams[1].indexValue);
        assertEq(iporIndexUsdtAfter, updateIndexParams[2].indexValue);
    }

    function testShouldNotSendEthToIporOracle() public payable {
        // given
        // when
        // then
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool status, ) = address(_iporOracle).call{value: msg.value}("");
        assertTrue(!status);
    }

    function testShouldCalculateDifferentInterestBearingTokenPriceOneSecondPeriodSameIporIndexValue6DecimalsAsset()
        public
    {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;

        vm.warp(updateDate);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_usdcTestnetToken), 5e16));

        updateDate++;

        (uint256 iporIndexBefore, uint256 ibtPriceBefore, ) = _iporOracle.getIndex(address(_usdcTestnetToken));

        vm.warp(updateDate);

        // when
        _iporOracle.updateIndexes(getIndexToUpdate(address(_usdcTestnetToken), 5e16));

        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(address(_usdcTestnetToken));

        assertEq(iporIndexBefore, 5e16);
        assertEq(iporIndexAfter, 5e16);

        assertEq(iporIndexAfter, iporIndexBefore);

        assertEq(ibtPriceBefore != ibtPriceAfter, true);
    }

    function testShouldCalculateNextAfterNextInterestBearingTokenPriceHalfYearAndThreeMonthsSnapshots() public {
        // given
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 6e16;
        uint256 iporIndexThirdValue = 7e16;
        uint256 expectedIbtPrice = 1040810774192388227;

        uint256 updateDate = _blockTimestamp + 60 * 60;
        vm.warp(updateDate);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_usdtTestnetToken), indexValueOne));

        updateDate += (365 * 24 * 60 * 60) / 2;
        vm.warp(updateDate);
        _iporOracle.updateIndexes(getIndexToUpdate(address(_usdtTestnetToken), indexValueTwo));

        updateDate += (365 * 24 * 60 * 60) / 4;
        vm.warp(updateDate);

        // when
        _iporOracle.updateIndexes(getIndexToUpdate(address(_usdtTestnetToken), iporIndexThirdValue));

        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexAfter, iporIndexThirdValue);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }
}
