// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/oracles/IporRiskManagementOracle.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/IIporRiskManagementOracle.sol";

contract IporRiskManagementOracleTest is Test, TestCommons {
    uint32 private _blockTimestamp = 1641701;
    uint32 private _blockTimestamp2 = 1641713;
    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    IporRiskManagementOracle private _iporRiskManagementOracle;

    function setUp() public {
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint64[] memory maxNotionalPayFixed = new uint64[](3);
        maxNotionalPayFixed[0] = TestConstants.RMO_NOTIONAL_1B;
        maxNotionalPayFixed[1] = TestConstants.RMO_NOTIONAL_1B;
        maxNotionalPayFixed[2] = TestConstants.RMO_NOTIONAL_1B;

        uint64[] memory maxNotionalReceiveFixed = new uint64[](3);
        maxNotionalReceiveFixed[0] = TestConstants.RMO_NOTIONAL_1B;
        maxNotionalReceiveFixed[1] = TestConstants.RMO_NOTIONAL_1B;
        maxNotionalReceiveFixed[2] = TestConstants.RMO_NOTIONAL_1B;

        uint16[] memory maxUtilizationRatePayFixed = new uint16[](3);
        maxUtilizationRatePayFixed[0] = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        maxUtilizationRatePayFixed[1] = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        maxUtilizationRatePayFixed[2] = TestConstants.RMO_UTILIZATION_RATE_48_PER;

        uint16[] memory maxUtilizationRateReceiveFixed = new uint16[](3);
        maxUtilizationRateReceiveFixed[0] = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        maxUtilizationRateReceiveFixed[1] = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        maxUtilizationRateReceiveFixed[2] = TestConstants.RMO_UTILIZATION_RATE_48_PER;

        uint16[] memory maxUtilizationRate = new uint16[](3);
        maxUtilizationRate[0] = TestConstants.RMO_UTILIZATION_RATE_90_PER;
        maxUtilizationRate[1] = TestConstants.RMO_UTILIZATION_RATE_90_PER;
        maxUtilizationRate[2] = TestConstants.RMO_UTILIZATION_RATE_90_PER;

        ERC1967Proxy iporRiskManagementOracleProxy = new ERC1967Proxy(
            address(iporRiskManagementOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint256[],uint256[],uint256[],uint256[],uint256[])",
                assets,
                maxNotionalPayFixed,
                maxNotionalReceiveFixed,
                maxUtilizationRatePayFixed,
                maxUtilizationRateReceiveFixed,
                maxUtilizationRate
            )
        );
        _iporRiskManagementOracle = IporRiskManagementOracle(address(iporRiskManagementOracleProxy));

        _iporRiskManagementOracle.addUpdater(address(this));
    }

    function testShouldReturnContractVersion() public {
        // given
        uint256 version = _iporRiskManagementOracle.getVersion();
        // then
        assertEq(version, 1);
    }

    function testShouldPauseSCWhenSenderIsAdmin() public {
        // given
        bool pausedBefore = _iporRiskManagementOracle.paused();
        // when
        _iporRiskManagementOracle.pause();
        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        _iporRiskManagementOracle.pause();
        bool pausedBefore = _iporRiskManagementOracle.paused();

        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_48_PER
        );

        address[] memory assets = new address[](2);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);

        uint256[] memory maxNotionalPayFixed = new uint256[](2);
        maxNotionalPayFixed[0] = TestConstants.RMO_NOTIONAL_2B;
        maxNotionalPayFixed[1] = TestConstants.RMO_NOTIONAL_2B;

        uint256[] memory maxNotionalReceiveFixed = new uint256[](2);
        maxNotionalReceiveFixed[0] = TestConstants.RMO_NOTIONAL_2B;
        maxNotionalReceiveFixed[1] = TestConstants.RMO_NOTIONAL_2B;

        uint256[] memory maxUtilizationRatePayFixed = new uint256[](2);
        maxUtilizationRatePayFixed[0] = TestConstants.RMO_UTILIZATION_RATE_30_PER;
        maxUtilizationRatePayFixed[1] = TestConstants.RMO_UTILIZATION_RATE_30_PER;

        uint256[] memory maxUtilizationRateReceiveFixed = new uint256[](2);
        maxUtilizationRateReceiveFixed[0] = TestConstants.RMO_UTILIZATION_RATE_30_PER;
        maxUtilizationRateReceiveFixed[1] = TestConstants.RMO_UTILIZATION_RATE_30_PER;

        uint256[] memory maxUtilizationRate = new uint256[](2);
        maxUtilizationRate[0] = TestConstants.RMO_UTILIZATION_RATE_80_PER;
        maxUtilizationRate[1] = TestConstants.RMO_UTILIZATION_RATE_80_PER;

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporRiskManagementOracle.updateRiskIndicators(
            assets,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        _iporRiskManagementOracle.pause();
        bool pausedBefore = _iporRiskManagementOracle.paused();

        //when
        _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        _iporRiskManagementOracle.isAssetSupported(address(_daiTestnetToken));
        _iporRiskManagementOracle.isUpdater(address(this));

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        bool pausedBefore = _iporRiskManagementOracle.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.pause();
        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _iporRiskManagementOracle.pause();
        bool pausedBefore = _iporRiskManagementOracle.paused();
        // when
        _iporRiskManagementOracle.unpause();
        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _iporRiskManagementOracle.pause();
        bool pausedBefore = _iporRiskManagementOracle.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.unpause();
        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldRemovedAsset() public {
        // given
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(_daiTestnetToken));
        // when
        _iporRiskManagementOracle.removeAsset(address(_daiTestnetToken));
        // then
        bool assetSupportedAfter = _iporRiskManagementOracle.isAssetSupported(address(_daiTestnetToken));

        assertEq(assetSupportedBefore, true);
        assertEq(assetSupportedAfter, false);
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporRiskManagementOracle.owner();
        // when
        _iporRiskManagementOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporRiskManagementOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporRiskManagementOracle.owner();
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.transferOwnership(newOwner);

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporRiskManagementOracle.owner();
        // when
        _iporRiskManagementOracle.transferOwnership(newOwner);
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        _iporRiskManagementOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);
        address ownerBefore = _iporRiskManagementOracle.owner();

        // when
        _iporRiskManagementOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporRiskManagementOracle.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        vm.prank(newOwner);
        _iporRiskManagementOracle.confirmTransferOwnership();

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporRiskManagementOracle.owner();
        // when
        _iporRiskManagementOracle.transferOwnership(newOwner);
        vm.prank(newOwner);
        _iporRiskManagementOracle.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHaveRights() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _iporRiskManagementOracle.owner();
        // when
        _iporRiskManagementOracle.transferOwnership(newOwner);
        _iporRiskManagementOracle.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _iporRiskManagementOracle.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldAddAsset() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));
        // when
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER
        );
        // then
        bool assetSupportedAfter = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        assertEq(assetSupportedBefore, false);
        assertEq(assetSupportedAfter, true);
    }

    function testShouldNotUpdateIndicatorsWhenUpdaterIsNotAnUpdater() public {
        // given
        vm.prank(_getUserAddress(1));

        // when
        vm.expectRevert(abi.encodePacked(IporRiskManagementOracleErrors.CALLER_NOT_UPDATER));
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_48_PER
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxUtilizationRatePayFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(maxUtilizationRateReceiveFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(maxUtilizationRate, uint256(TestConstants.RMO_UTILIZATION_RATE_90_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldNotUpdateIndicatorsWhenUpdaterWasRemoved() public {
        // given
        uint256 isUpdaterBeforeRemove = _iporRiskManagementOracle.isUpdater(address(this));
        _iporRiskManagementOracle.removeUpdater(address(this));
        uint256 isUpdaterAfterRemove = _iporRiskManagementOracle.isUpdater(address(this));

        // when
        vm.expectRevert(abi.encodePacked(IporRiskManagementOracleErrors.CALLER_NOT_UPDATER));
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_48_PER
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(isUpdaterBeforeRemove, 1);
        assertEq(isUpdaterAfterRemove, 0);
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxUtilizationRatePayFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(maxUtilizationRateReceiveFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(maxUtilizationRate, uint256(TestConstants.RMO_UTILIZATION_RATE_90_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldUpdateIndicators() public {
        // given
        vm.warp(_blockTimestamp2);

        // when
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_30_PER,
            TestConstants.RMO_UTILIZATION_RATE_48_PER
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxUtilizationRatePayFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_30_PER) * 1e14);
        assertEq(maxUtilizationRateReceiveFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_30_PER) * 1e14);
        assertEq(maxUtilizationRate, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp2);
    }

    function testShouldUpdateMultipleIndicators() public {
        // given
        vm.warp(_blockTimestamp2);

        address[] memory assets = new address[](2);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);

        uint256[] memory maxNotionalPayFixed = new uint256[](2);
        maxNotionalPayFixed[0] = TestConstants.RMO_NOTIONAL_2B;
        maxNotionalPayFixed[1] = TestConstants.RMO_NOTIONAL_3B;

        uint256[] memory maxNotionalReceiveFixed = new uint256[](2);
        maxNotionalReceiveFixed[0] = TestConstants.RMO_NOTIONAL_2B;
        maxNotionalReceiveFixed[1] = TestConstants.RMO_NOTIONAL_10B;

        uint256[] memory maxUtilizationRatePayFixed = new uint256[](2);
        maxUtilizationRatePayFixed[0] = TestConstants.RMO_UTILIZATION_RATE_30_PER;
        maxUtilizationRatePayFixed[1] = TestConstants.RMO_UTILIZATION_RATE_20_PER;

        uint256[] memory maxUtilizationRateReceiveFixed = new uint256[](2);
        maxUtilizationRateReceiveFixed[0] = TestConstants.RMO_UTILIZATION_RATE_30_PER;
        maxUtilizationRateReceiveFixed[1] = TestConstants.RMO_UTILIZATION_RATE_35_PER;

        uint256[] memory maxUtilizationRate = new uint256[](2);
        maxUtilizationRate[0] = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        maxUtilizationRate[1] = TestConstants.RMO_UTILIZATION_RATE_60_PER;


        // when
        _iporRiskManagementOracle.updateRiskIndicators(
            assets,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );

        // then
        (
            uint256 daiMaxNotionalPayFixed,
            uint256 daiMaxNotionalReceiveFixed,
            uint256 daiMaxUtilizationRatePayFixed,
            uint256 daiMaxUtilizationRateReceiveFixed,
            uint256 daiMaxUtilizationRate,
            uint256 daiLastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(daiMaxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(daiMaxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(daiMaxUtilizationRatePayFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_30_PER) * 1e14);
        assertEq(daiMaxUtilizationRateReceiveFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_30_PER) * 1e14);
        assertEq(daiMaxUtilizationRate, uint256(TestConstants.RMO_UTILIZATION_RATE_48_PER) * 1e14);
        assertEq(daiLastUpdateTimestamp, _blockTimestamp2);
        (
            uint256 usdcMaxNotionalPayFixed,
            uint256 usdcMaxNotionalReceiveFixed,
            uint256 usdcMaxUtilizationRatePayFixed,
            uint256 usdcMaxUtilizationRateReceiveFixed,
            uint256 usdcMaxUtilizationRate,
            uint256 usdcLastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_usdcTestnetToken));
        assertEq(usdcMaxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_3B) * 1e22);
        assertEq(usdcMaxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_10B) * 1e22);
        assertEq(usdcMaxUtilizationRatePayFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_20_PER) * 1e14);
        assertEq(usdcMaxUtilizationRateReceiveFixed, uint256(TestConstants.RMO_UTILIZATION_RATE_35_PER) * 1e14);
        assertEq(usdcMaxUtilizationRate, uint256(TestConstants.RMO_UTILIZATION_RATE_60_PER) * 1e14);
        assertEq(usdcLastUpdateTimestamp, _blockTimestamp2);
    }

    function testShouldNotAddUpdaterWhenNotOwner() public {
        // given
        address updater = _getUserAddress(1);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.addUpdater(updater);
        // then
        uint256 isUpdater = _iporRiskManagementOracle.isUpdater(updater);
        assertEq(isUpdater, 0);
    }

    function testShouldRemoveUpdater() public {
        // given
        uint256 isUpdaterBefore = _iporRiskManagementOracle.isUpdater(address(this));

        // when
        _iporRiskManagementOracle.removeUpdater(address(this));

        // then
        uint256 isUpdaterAfter = _iporRiskManagementOracle.isUpdater(address(this));

        assertEq(isUpdaterBefore, 1);
        assertEq(isUpdaterAfter, 0);
    }

    function testShouldNotRemoveUpdaterWhenNotOwner() public {
        // given
        address updater = address(this);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporRiskManagementOracle.removeUpdater(updater);
        // then
        uint256 isUpdater = _iporRiskManagementOracle.isUpdater(updater);
        assertEq(isUpdater, 1);
    }
}
