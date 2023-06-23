// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "test/TestCommons.sol";
import "../utils/TestConstants.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";
import "contracts/interfaces/IIporRiskManagementOracle.sol";
import "contracts/interfaces/types/IporRiskManagementOracleTypes.sol";
import "contracts/oracles/OraclePublisher.sol";

contract OraclePublisherTest is Test, TestCommons {
    uint256 private _blockTimestamp = 1625097600;
    uint256 private _blockTimestamp2 = _blockTimestamp + 1 days;

    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;

    IporOracle private _iporOracle;
    IporRiskManagementOracle private _iporRiskManagementOracle;

    OraclePublisher private _oraclePublisher;

    function setUp() public {
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);

        IporOracle iporOracleImplementation = new IporOracle(
            address(_usdtTestnetToken),
            1e18,
            address(_usdcTestnetToken),
            1e18,
            address(_daiTestnetToken),
            1e18
        );
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature("initialize(address[],uint32[])", assets, updateTimestamps)
        );
        _iporOracle = IporOracle(address(iporOracleProxy));

        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicators = new IporRiskManagementOracleTypes.RiskIndicators[](3);
        riskIndicators[0] = IporRiskManagementOracleTypes.RiskIndicators(
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER
        );
        riskIndicators[1] = IporRiskManagementOracleTypes.RiskIndicators(
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER
        );
        riskIndicators[2] = IporRiskManagementOracleTypes.RiskIndicators(
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER
        );

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsAndFixedRateCaps = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](3);
        baseSpreadsAndFixedRateCaps[0] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
        );
        baseSpreadsAndFixedRateCaps[1] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
        );
        baseSpreadsAndFixedRateCaps[2] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_SPREAD_0_1_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
            TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
            TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
        );

        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();
        ERC1967Proxy iporRiskManagementOracleProxy = new ERC1967Proxy(
            address(iporRiskManagementOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
                assets,
                riskIndicators,
                baseSpreadsAndFixedRateCaps
            )
        );
        _iporRiskManagementOracle = IporRiskManagementOracle(address(iporRiskManagementOracleProxy));

        OraclePublisher oraclePublisherImplementation = new OraclePublisher(
            address(_iporOracle),
            address(_iporRiskManagementOracle)
        );
        ERC1967Proxy oraclePublisherProxy = new ERC1967Proxy(
            address(oraclePublisherImplementation),
            abi.encodeWithSignature("initialize()")
        );

        _oraclePublisher = OraclePublisher(address(oraclePublisherProxy));
        _oraclePublisher.addUpdater(address(this));
        _iporOracle.addUpdater(address(_oraclePublisher));
        _iporRiskManagementOracle.addUpdater(address(_oraclePublisher));
    }

    function testShouldReturnContractVersion() public {
        // given
        uint256 version = _oraclePublisher.getVersion();
        // then
        assertEq(version, 2_000);
    }

    function testShouldPauseSCWhenSenderIsAdmin() public {
        // given
        bool pausedBefore = _oraclePublisher.paused();
        // when
        _oraclePublisher.pause();
        // then
        bool pausedAfter = _oraclePublisher.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        _oraclePublisher.pause();
        bool pausedBefore = _oraclePublisher.paused();

        bytes memory updateIndexCallData = abi.encodeWithSignature(
            "updateIndex(address,uint256)",
            address(_daiTestnetToken),
            TestConstants.PERCENTAGE_2_5_18DEC
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateIndexCallData;
        // when

        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _oraclePublisher.publish(addresses, calls);

        // then
        bool pausedAfter = _oraclePublisher.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        bool pausedBefore = _oraclePublisher.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.pause();
        // then
        bool pausedAfter = _oraclePublisher.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _oraclePublisher.pause();
        bool pausedBefore = _oraclePublisher.paused();
        // when
        _oraclePublisher.unpause();
        // then
        bool pausedAfter = _oraclePublisher.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _oraclePublisher.pause();
        bool pausedBefore = _oraclePublisher.paused();
        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.unpause();
        // then
        bool pausedAfter = _oraclePublisher.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _oraclePublisher.owner();
        // when
        _oraclePublisher.transferOwnership(newOwner);
        vm.prank(newOwner);
        _oraclePublisher.confirmTransferOwnership();

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _oraclePublisher.owner();
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.transferOwnership(newOwner);

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _oraclePublisher.owner();
        // when
        _oraclePublisher.transferOwnership(newOwner);
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        _oraclePublisher.confirmTransferOwnership();

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);
        address ownerBefore = _oraclePublisher.owner();

        // when
        _oraclePublisher.transferOwnership(newOwner);
        vm.prank(newOwner);
        _oraclePublisher.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        vm.prank(newOwner);
        _oraclePublisher.confirmTransferOwnership();

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _oraclePublisher.owner();
        // when
        _oraclePublisher.transferOwnership(newOwner);
        vm.prank(newOwner);
        _oraclePublisher.confirmTransferOwnership();
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, newOwner);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHaveRights() public {
        // given
        address newOwner = _getUserAddress(1);
        address oldOwner = address(this);

        address ownerBefore = _oraclePublisher.owner();
        // when
        _oraclePublisher.transferOwnership(newOwner);
        _oraclePublisher.transferOwnership(_getUserAddress(2));

        // then
        address ownerAfter = _oraclePublisher.owner();

        assertEq(ownerBefore, oldOwner);
        assertEq(ownerAfter, oldOwner);
    }

    function testShouldNotUpdateIndexWhenUpdaterIsNotAnUpdater() public {
        // given
        vm.prank(_getUserAddress(1));
        bytes memory updateIndexCallData = abi.encodeWithSignature(
            "updateIndex(address,uint256)",
            address(_daiTestnetToken),
            TestConstants.PERCENTAGE_2_5_18DEC
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateIndexCallData;

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        _oraclePublisher.publish(addresses, calls);

        // then
        (uint256 indexValue, , uint256 lastUpdateTimestamp) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(indexValue, 0);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldNotUpdateIndexWhenUpdaterWasRemoved() public {
        // given
        uint256 isUpdaterBeforeRemove = _oraclePublisher.isUpdater(address(this));
        _oraclePublisher.removeUpdater(address(this));
        uint256 isUpdaterAfterRemove = _oraclePublisher.isUpdater(address(this));

        bytes memory updateIndexCallData = abi.encodeWithSignature(
            "updateIndex(address,uint256)",
            address(_daiTestnetToken),
            TestConstants.PERCENTAGE_2_5_18DEC
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateIndexCallData;

        // when
        vm.expectRevert(abi.encodePacked(IporOracleErrors.CALLER_NOT_UPDATER));
        _oraclePublisher.publish(addresses, calls);

        // then
        (uint256 indexValue, , uint256 lastUpdateTimestamp) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(indexValue, 0);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldUpdateIndex() public {
        // given
        vm.warp(_blockTimestamp2);

        bytes memory updateIndexCallData = abi.encodeWithSignature(
            "updateIndex(address,uint256)",
            address(_daiTestnetToken),
            TestConstants.PERCENTAGE_2_5_18DEC
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateIndexCallData;

        // when
        _oraclePublisher.publish(addresses, calls);

        // then
        (uint256 indexValue, , uint256 lastUpdateTimestamp) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(indexValue, TestConstants.PERCENTAGE_2_5_18DEC);
        assertEq(lastUpdateTimestamp, _blockTimestamp2);
    }

    function testShouldUpdateIndicators() public {
        // given
        vm.warp(_blockTimestamp2);

        bytes memory updateIndicatorsCallData = abi.encodeWithSignature(
            "updateRiskIndicators(address,uint256,uint256,uint256,uint256,uint256)",
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporRiskManagementOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateIndicatorsCallData;

        // when
        _oraclePublisher.publish(addresses, calls);

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxCollateralRatioPayFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_30_PER) * 1e14);
        assertEq(maxCollateralRatioReceiveFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_30_PER) * 1e14);
        assertEq(maxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp2);
    }

    function testShouldUpdateBaseSpreadsAndFixedRateCaps() public {
        // given
        vm.warp(_blockTimestamp2);

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory input = IporRiskManagementOracleTypes
            .BaseSpreadsAndFixedRateCaps(
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_25_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_25_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_25_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER
            );
        bytes memory updateBaseSpreadAndFixedRateCapsCallData = abi.encodeWithSignature(
            "updateBaseSpreadsAndFixedRateCaps(address,(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256))",
            address(_daiTestnetToken),
            input
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(_iporRiskManagementOracle);
        bytes[] memory calls = new bytes[](1);
        calls[0] = updateBaseSpreadAndFixedRateCapsCallData;

        // when
        _oraclePublisher.publish(addresses, calls);

        // then
        (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        ) = _iporRiskManagementOracle.getBaseSpreads(address(_daiTestnetToken));
        assertEq(spread28dPayFixed, int256(TestConstants.RMO_SPREAD_0_2_PER) * 1e12);
        assertEq(spread28dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_25_PER) * 1e12);
        assertEq(spread60dPayFixed, int256(TestConstants.RMO_SPREAD_0_2_PER) * 1e12);
        assertEq(spread60dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_25_PER) * 1e12);
        assertEq(spread90dPayFixed, int256(TestConstants.RMO_SPREAD_0_2_PER) * 1e12);
        assertEq(spread90dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_25_PER) * 1e12);
        assertEq(lastUpdateTimestamp, _blockTimestamp2);
        (
            uint256 lastUpdateTimestampFixedRateCap,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(_daiTestnetToken));
        assertEq(fixedRateCap28dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(fixedRateCap28dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(fixedRateCap60dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(fixedRateCap60dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(fixedRateCap90dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(fixedRateCap90dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
        assertEq(lastUpdateTimestampFixedRateCap, _blockTimestamp2);
    }

    function testShouldUpdateMultipleOracles() public {
        // given
        vm.warp(_blockTimestamp2);

        address[] memory addresses = new address[](2);
        bytes[] memory calls = new bytes[](2);

        bytes memory updateIndexCallData = abi.encodeWithSignature(
            "updateIndex(address,uint256)",
            address(_daiTestnetToken),
            TestConstants.PERCENTAGE_2_5_18DEC
        );
        addresses[0] = address(_iporOracle);
        calls[0] = updateIndexCallData;

        bytes memory updateIndicatorsCallData = abi.encodeWithSignature(
            "updateRiskIndicators(address,uint256,uint256,uint256,uint256,uint256)",
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );
        addresses[1] = address(_iporRiskManagementOracle);
        calls[1] = updateIndicatorsCallData;

        // when
        _oraclePublisher.publish(addresses, calls);

        // then
        (uint256 indexValue, , uint256 lastUpdateTimestampIndex) = _iporOracle.getIndex(address(_daiTestnetToken));
        assertEq(indexValue, TestConstants.PERCENTAGE_2_5_18DEC);
        assertEq(lastUpdateTimestampIndex, _blockTimestamp2);
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestampRiskIndicators
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(maxCollateralRatioPayFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_30_PER) * 1e14);
        assertEq(maxCollateralRatioReceiveFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_30_PER) * 1e14);
        assertEq(maxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(lastUpdateTimestampRiskIndicators, _blockTimestamp2);
    }

    function testShouldNotAddUpdaterWhenNotOwner() public {
        // given
        address updater = _getUserAddress(1);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.addUpdater(updater);
        // then
        uint256 isUpdater = _iporRiskManagementOracle.isUpdater(updater);
        assertEq(isUpdater, 0);
    }

    function testShouldRemoveUpdater() public {
        // given
        uint256 isUpdaterBefore = _oraclePublisher.isUpdater(address(this));

        // when
        _oraclePublisher.removeUpdater(address(this));

        // then
        uint256 isUpdaterAfter = _oraclePublisher.isUpdater(address(this));

        assertEq(isUpdaterBefore, 1);
        assertEq(isUpdaterAfter, 0);
    }

    function testShouldNotRemoveUpdaterWhenNotOwner() public {
        // given
        address updater = address(this);
        // when
        vm.prank(_getUserAddress(2));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _oraclePublisher.removeUpdater(updater);
        // then
        uint256 isUpdater = _oraclePublisher.isUpdater(updater);
        assertEq(isUpdater, 1);
    }
}
