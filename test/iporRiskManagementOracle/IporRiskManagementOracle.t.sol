// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/oracles/IporRiskManagementOracle.sol";
import "../../contracts/interfaces/types/IporRiskManagementOracleTypes.sol";

contract IporRiskManagementOracleTest is Test, TestCommons {
    uint32 private _blockTimestamp = 1641701;
    uint32 private _blockTimestamp2 = 1641713;
    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    IporRiskManagementOracle private _iporRiskManagementOracle;

    function setUp() public {
        _admin = address(this);
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

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

        _iporRiskManagementOracle.addUpdater(address(this));
    }

    function testShouldReturnContractVersion() public {
        // given
        uint256 version = _iporRiskManagementOracle.getVersion();
        // then
        assertEq(version, 2_000);
    }

    function testShouldPauseSCWhenSenderIsPauseGuardian() public {
        // given
        bool pausedBefore = _iporRiskManagementOracle.paused();
        _iporRiskManagementOracle.addPauseGuardian(_admin);

        // when
        _iporRiskManagementOracle.pause();

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        _iporRiskManagementOracle.addPauseGuardian(_admin);
        _iporRiskManagementOracle.pause();
        bool pausedBefore = _iporRiskManagementOracle.paused();

        new MockTestnetToken("Random Stable", "SandomStable", 100_000_000 * 1e18, uint8(18));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory baseSpreads1 = IporRiskManagementOracleTypes
            .BaseSpreadsAndFixedRateCaps({
                spread28dPayFixed: TestConstants.RMO_SPREAD_0_2_PER,
                spread28dReceiveFixed: TestConstants.RMO_SPREAD_0_2_PER,
                spread60dPayFixed: TestConstants.RMO_SPREAD_0_25_PER,
                spread60dReceiveFixed: TestConstants.RMO_SPREAD_0_25_PER,
                spread90dPayFixed: TestConstants.RMO_SPREAD_0_25_PER,
                spread90dReceiveFixed: TestConstants.RMO_SPREAD_0_25_PER,
                fixedRateCap28dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap28dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                fixedRateCap60dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap60dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                fixedRateCap90dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap90dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
            });
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(address(_daiTestnetToken), baseSpreads1);

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        _iporRiskManagementOracle.addPauseGuardian(_admin);
        _iporRiskManagementOracle.pause();

        bool pausedBefore = _iporRiskManagementOracle.paused();

        //when
        vm.startPrank(_getUserAddress(1));
        _iporRiskManagementOracle.getVersion();
        _iporRiskManagementOracle.getOpenSwapParameters(address(_daiTestnetToken), 1, IporTypes.SwapTenor.DAYS_28);
        _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        _iporRiskManagementOracle.getBaseSpreads(address(_daiTestnetToken));
        _iporRiskManagementOracle.getFixedRateCaps(address(_daiTestnetToken));
        _iporRiskManagementOracle.isAssetSupported(address(_daiTestnetToken));
        _iporRiskManagementOracle.isUpdater(address(this));
        _iporRiskManagementOracle.isPauseGuardian(address(this));
        vm.stopPrank();

        //admin
        _iporRiskManagementOracle.addUpdater(address(this));
        _iporRiskManagementOracle.removeUpdater(address(this));
        _iporRiskManagementOracle.addPauseGuardian(address(this));
        _iporRiskManagementOracle.removePauseGuardian(address(this));

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnPauseGuardian() public {
        // given
        bool pausedBefore = _iporRiskManagementOracle.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        _iporRiskManagementOracle.pause();
        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _iporRiskManagementOracle.addPauseGuardian(_admin);
        _iporRiskManagementOracle.pause();
        _iporRiskManagementOracle.removePauseGuardian(_admin);

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
        _iporRiskManagementOracle.addPauseGuardian(_admin);
        _iporRiskManagementOracle.pause();
        _iporRiskManagementOracle.removePauseGuardian(_admin);

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
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
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
            )
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
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxCollateralRatioPayFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatioReceiveFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_90_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldNotUpdateBaseSpreadsWhenUpdaterIsNotAnUpdater() public {
        // given
        vm.prank(_getUserAddress(1));

        // when
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory input = IporRiskManagementOracleTypes
            .BaseSpreadsAndFixedRateCaps(
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER
            );
        vm.expectRevert(abi.encodePacked(IporRiskManagementOracleErrors.CALLER_NOT_UPDATER));
        _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(address(_daiTestnetToken), input);

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
        assertEq(spread28dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread28dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread60dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread60dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread90dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread90dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
        (
            uint256 lastUpdateTimestampFixedRateCap,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(_daiTestnetToken));
        assertEq(fixedRateCap28dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap28dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(fixedRateCap60dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap60dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(fixedRateCap90dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap90dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(lastUpdateTimestampFixedRateCap, _blockTimestamp);
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
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken));
        assertEq(isUpdaterBeforeRemove, 1);
        assertEq(isUpdaterAfterRemove, 0);
        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxCollateralRatioPayFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatioReceiveFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_90_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
    }

    function testShouldNotUpdateBaseSpreadsWhenUpdaterWasRemoved() public {
        // given
        uint256 isUpdaterBeforeRemove = _iporRiskManagementOracle.isUpdater(address(this));
        _iporRiskManagementOracle.removeUpdater(address(this));
        uint256 isUpdaterAfterRemove = _iporRiskManagementOracle.isUpdater(address(this));

        // when
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory input = IporRiskManagementOracleTypes
            .BaseSpreadsAndFixedRateCaps(
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_SPREAD_0_2_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER,
                TestConstants.RMO_FIXED_RATE_CAP_4_0_PER
            );
        vm.expectRevert(abi.encodePacked(IporRiskManagementOracleErrors.CALLER_NOT_UPDATER));
        _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(address(_daiTestnetToken), input);

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
        assertEq(isUpdaterBeforeRemove, 1);
        assertEq(isUpdaterAfterRemove, 0);
        assertEq(spread28dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread28dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread60dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread60dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread90dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(spread90dReceiveFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
        (
            uint256 lastUpdateTimestampFixedRateCap,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(_daiTestnetToken));
        assertEq(fixedRateCap28dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap28dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(fixedRateCap60dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap60dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(fixedRateCap90dPayFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14);
        assertEq(fixedRateCap90dReceiveFixed, uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14);
        assertEq(lastUpdateTimestampFixedRateCap, _blockTimestamp);
    }

    function testShouldUpdateIndicators() public {
        // given
        vm.warp(_blockTimestamp2);

        // when
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );

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

        // when
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
        _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(address(_daiTestnetToken), input);

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

    function testShouldRetrieveOpenSwapParameters() public {
        // given
        vm.warp(_blockTimestamp2);
        _iporRiskManagementOracle.updateRiskIndicators(
            address(_daiTestnetToken),
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_30_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER
        );
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
        _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(address(_daiTestnetToken), input);

        // when
        (
            uint256 daiPayFixed60DMaxNotionalPerLeg,
            uint256 daiPayFixed60DMaxCollateralRatioPerLeg,
            uint256 daiPayFixed60DMaxCollateralRatio,
            int256 daiPayFixed60DSpread,
            uint256 daiFixedRateCap60D
        ) = _iporRiskManagementOracle.getOpenSwapParameters(
                address(_daiTestnetToken),
                TestConstants.LEG_PAY_FIXED,
                IporTypes.SwapTenor.DAYS_60
            );
        (
            uint256 daiReceiveFixed90DMaxNotionalPerLeg,
            uint256 daiReceiveFixed90DMaxCollateralRatioPerLeg,
            uint256 daiReceiveFixed90DMaxCollateralRatio,
            int256 daiReceiveFixed90DSpread,
            uint256 daiFixedRateCap90D
        ) = _iporRiskManagementOracle.getOpenSwapParameters(
                address(_daiTestnetToken),
                TestConstants.LEG_RECEIVE_FIXED,
                IporTypes.SwapTenor.DAYS_90
            );

        //then:
        assertEq(daiPayFixed60DMaxNotionalPerLeg, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(daiPayFixed60DMaxCollateralRatioPerLeg, uint256(TestConstants.RMO_COLLATERAL_RATIO_30_PER) * 1e14);
        assertEq(daiPayFixed60DMaxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(daiPayFixed60DSpread, int256(TestConstants.RMO_SPREAD_0_2_PER) * 1e12);
        assertEq(daiFixedRateCap60D, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);

        assertEq(daiReceiveFixed90DMaxNotionalPerLeg, uint256(TestConstants.RMO_NOTIONAL_2B) * 1e22);
        assertEq(daiReceiveFixed90DMaxCollateralRatioPerLeg, uint256(TestConstants.RMO_COLLATERAL_RATIO_20_PER) * 1e14);
        assertEq(daiReceiveFixed90DMaxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(daiReceiveFixed90DSpread, int256(TestConstants.RMO_SPREAD_0_25_PER) * 1e12);
        assertEq(daiFixedRateCap90D, uint256(TestConstants.RMO_FIXED_RATE_CAP_4_0_PER) * 1e14);
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
