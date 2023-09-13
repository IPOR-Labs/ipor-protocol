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

    struct FixedRateCaps {
        uint256 fixedRateCap28dPayFixed;
        uint256 fixedRateCap28dReceiveFixed;
        uint256 fixedRateCap60dPayFixed;
        uint256 fixedRateCap60dReceiveFixed;
        uint256 fixedRateCap90dPayFixed;
        uint256 fixedRateCap90dReceiveFixed;
    }

    struct BaseSpreads {
        int256 spread28dPayFixed;
        int256 spread28dReceiveFixed;
        int256 spread60dPayFixed;
        int256 spread60dReceiveFixed;
        int256 spread90dPayFixed;
        int256 spread90dReceiveFixed;
    }

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
            TestConstants.RMO_COLLATERAL_RATIO_90_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
        );
        riskIndicators[1] = IporRiskManagementOracleTypes.RiskIndicators(
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
        );
        riskIndicators[2] = IporRiskManagementOracleTypes.RiskIndicators(
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
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
                "initialize(address[],(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
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

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);

        // when
        _iporRiskManagementOracle.pause();

        // then
        bool pausedAfter = _iporRiskManagementOracle.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldPauseSCSpecificMethods() public {
        // given
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);
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
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
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
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);
        _iporRiskManagementOracle.pause();

        bool pausedBefore = _iporRiskManagementOracle.paused();

        //when
        vm.startPrank(_getUserAddress(1));
        _iporRiskManagementOracle.getVersion();
        _iporRiskManagementOracle.getOpenSwapParameters(address(_daiTestnetToken), 1, IporTypes.SwapTenor.DAYS_28);
        _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_28);
        _iporRiskManagementOracle.getBaseSpreads(address(_daiTestnetToken));
        _iporRiskManagementOracle.getFixedRateCaps(address(_daiTestnetToken));
        _iporRiskManagementOracle.isAssetSupported(address(_daiTestnetToken));
        _iporRiskManagementOracle.isUpdater(address(this));
        _iporRiskManagementOracle.isPauseGuardian(address(this));
        vm.stopPrank();

        //admin
        pauseGuardians[0] = address(this);
        _iporRiskManagementOracle.addUpdater(address(this));
        _iporRiskManagementOracle.removeUpdater(address(this));
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);
        _iporRiskManagementOracle.removePauseGuardians(pauseGuardians);

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
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);
        _iporRiskManagementOracle.pause();
        _iporRiskManagementOracle.removePauseGuardians(pauseGuardians);

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
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporRiskManagementOracle.addPauseGuardians(pauseGuardians);
        _iporRiskManagementOracle.pause();
        _iporRiskManagementOracle.removePauseGuardians(pauseGuardians);

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

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
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
        (
            ,
            fixedRateCaps.fixedRateCap28dPayFixed,
            fixedRateCaps.fixedRateCap28dReceiveFixed,
            fixedRateCaps.fixedRateCap60dPayFixed,
            fixedRateCaps.fixedRateCap60dReceiveFixed,
            fixedRateCaps.fixedRateCap90dPayFixed,
            fixedRateCaps.fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(randomStable));

        (
            ,
            baseSpread.spread28dPayFixed,
            baseSpread.spread28dReceiveFixed,
            baseSpread.spread60dPayFixed,
            baseSpread.spread60dReceiveFixed,
            baseSpread.spread90dPayFixed,
            baseSpread.spread90dReceiveFixed
        ) = _iporRiskManagementOracle.getBaseSpreads(address(randomStable));

        assertEq(assetSupportedBefore, false);
        assertEq(assetSupportedAfter, true);

        assertEq(baseSpread.spread28dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12, "spread28dPayFixed");
        assertEq(
            baseSpread.spread28dReceiveFixed,
            int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12,
            "spread28dReceiveFixed"
        );
        assertEq(baseSpread.spread60dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12, "spread60dPayFixed");
        assertEq(
            baseSpread.spread60dReceiveFixed,
            int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12,
            "spread60dReceiveFixed"
        );
        assertEq(baseSpread.spread90dPayFixed, int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12, "spread90dPayFixed");
        assertEq(
            baseSpread.spread90dReceiveFixed,
            int256(TestConstants.RMO_SPREAD_0_1_PER) * 1e12,
            "spread90dReceiveFixed"
        );

        assertEq(
            fixedRateCaps.fixedRateCap28dPayFixed,
            uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14,
            "fixedRateCap28dPayFixed"
        );
        assertEq(
            fixedRateCaps.fixedRateCap28dReceiveFixed,
            uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14,
            "fixedRateCap28dReceiveFixed"
        );
        assertEq(
            fixedRateCaps.fixedRateCap60dPayFixed,
            uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14,
            "fixedRateCap60dPayFixed"
        );
        assertEq(
            fixedRateCaps.fixedRateCap60dReceiveFixed,
            uint256(TestConstants.RMO_FIXED_RATE_CAP_3_5_PER) * 1e14,
            "fixedRateCap60dReceiveFixed"
        );
        assertEq(
            fixedRateCaps.fixedRateCap90dPayFixed,
            uint256(TestConstants.RMO_FIXED_RATE_CAP_2_0_PER) * 1e14,
            "fixedRateCap90dPayFixed"
        );
    }

    function testShouldAddAssetWhenPassMaxValue() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                type(int24).max - 1,
                type(int24).max - 1,
                type(int24).max - 1,
                type(int24).max - 1,
                type(int24).max - 1,
                type(int24).max - 1,
                2 ** 12 - 1,
                2 ** 12 - 1,
                2 ** 12 - 1,
                2 ** 12 - 1,
                2 ** 12 - 1,
                2 ** 12 - 1
            )
        );
        // then
        bool assetSupportedAfter = _iporRiskManagementOracle.isAssetSupported(address(randomStable));
        (
            ,
            fixedRateCaps.fixedRateCap28dPayFixed,
            fixedRateCaps.fixedRateCap28dReceiveFixed,
            fixedRateCaps.fixedRateCap60dPayFixed,
            fixedRateCaps.fixedRateCap60dReceiveFixed,
            fixedRateCaps.fixedRateCap90dPayFixed,
            fixedRateCaps.fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(randomStable));

        (
            ,
            baseSpread.spread28dPayFixed,
            baseSpread.spread28dReceiveFixed,
            baseSpread.spread60dPayFixed,
            baseSpread.spread60dReceiveFixed,
            baseSpread.spread90dPayFixed,
            baseSpread.spread90dReceiveFixed
        ) = _iporRiskManagementOracle.getBaseSpreads(address(randomStable));

        assertEq(assetSupportedBefore, false);
        assertEq(assetSupportedAfter, true);

        assertEq(baseSpread.spread28dPayFixed, int256(type(int24).max - 1) * 1e12, "spread28dPayFixed");
        assertEq(baseSpread.spread28dReceiveFixed, int256(type(int24).max - 1) * 1e12, "spread28dReceiveFixed");
        assertEq(baseSpread.spread60dPayFixed, int256(type(int24).max - 1) * 1e12, "spread60dPayFixed");
        assertEq(baseSpread.spread60dReceiveFixed, int256(type(int24).max - 1) * 1e12, "spread60dReceiveFixed");
        assertEq(baseSpread.spread90dPayFixed, int256(type(int24).max - 1) * 1e12, "spread90dPayFixed");
        assertEq(baseSpread.spread90dReceiveFixed, int256(type(int24).max - 1) * 1e12, "spread90dReceiveFixed");

        assertEq(fixedRateCaps.fixedRateCap28dPayFixed, uint256(2 ** 12 - 1) * 1e14, "fixedRateCap28dPayFixed");
        assertEq(fixedRateCaps.fixedRateCap28dReceiveFixed, uint256(2 ** 12 - 1) * 1e14, "fixedRateCap28dReceiveFixed");
        assertEq(fixedRateCaps.fixedRateCap60dPayFixed, uint256(2 ** 12 - 1) * 1e14, "fixedRateCap60dPayFixed");
        assertEq(fixedRateCaps.fixedRateCap60dReceiveFixed, uint256(2 ** 12 - 1) * 1e14, "fixedRateCap60dReceiveFixed");
        assertEq(fixedRateCaps.fixedRateCap90dPayFixed, uint256(2 ** 12 - 1) * 1e14, "fixedRateCap90dPayFixed");
    }

    function testShouldAddAssetWhenPassMinValue() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
        // then
        bool assetSupportedAfter = _iporRiskManagementOracle.isAssetSupported(address(randomStable));
        (
            ,
            fixedRateCaps.fixedRateCap28dPayFixed,
            fixedRateCaps.fixedRateCap28dReceiveFixed,
            fixedRateCaps.fixedRateCap60dPayFixed,
            fixedRateCaps.fixedRateCap60dReceiveFixed,
            fixedRateCaps.fixedRateCap90dPayFixed,
            fixedRateCaps.fixedRateCap90dReceiveFixed
        ) = _iporRiskManagementOracle.getFixedRateCaps(address(randomStable));

        (
            ,
            baseSpread.spread28dPayFixed,
            baseSpread.spread28dReceiveFixed,
            baseSpread.spread60dPayFixed,
            baseSpread.spread60dReceiveFixed,
            baseSpread.spread90dPayFixed,
            baseSpread.spread90dReceiveFixed
        ) = _iporRiskManagementOracle.getBaseSpreads(address(randomStable));

        assertEq(assetSupportedBefore, false);
        assertEq(assetSupportedAfter, true);

        assertEq(baseSpread.spread28dPayFixed, int256(-type(int24).max + 1) * 1e12, "spread28dPayFixed");
        assertEq(baseSpread.spread28dReceiveFixed, int256(-type(int24).max + 1) * 1e12, "spread28dReceiveFixed");
        assertEq(baseSpread.spread60dPayFixed, int256(-type(int24).max + 1) * 1e12, "spread60dPayFixed");
        assertEq(baseSpread.spread60dReceiveFixed, int256(-type(int24).max + 1) * 1e12, "spread60dReceiveFixed");
        assertEq(baseSpread.spread90dPayFixed, int256(-type(int24).max + 1) * 1e12, "spread90dPayFixed");
        assertEq(baseSpread.spread90dReceiveFixed, int256(-type(int24).max + 1) * 1e12, "spread90dReceiveFixed");

        assertEq(fixedRateCaps.fixedRateCap28dPayFixed, 0, "fixedRateCap28dPayFixed");
        assertEq(fixedRateCaps.fixedRateCap28dReceiveFixed, 0, "fixedRateCap28dReceiveFixed");
        assertEq(fixedRateCaps.fixedRateCap60dPayFixed, 0, "fixedRateCap60dPayFixed");
        assertEq(fixedRateCaps.fixedRateCap60dReceiveFixed, 0, "fixedRateCap60dReceiveFixed");
        assertEq(fixedRateCaps.fixedRateCap90dPayFixed, 0, "fixedRateCap90dPayFixed");
    }

    function testShouldRevertWhenSpread28dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread28dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread28dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread28dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread60dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread60dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread60dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread60dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread90dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread90dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread90dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread90dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread28dPayFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread28dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread28dReceiveFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread28dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread60dPayFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread60dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread60dReceiveFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread60dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max,
                -type(int24).max + 1,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread90dPayFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread90dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max,
                -type(int24).max + 1,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenSpread90dReceiveFixedToSmall() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("spread90dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap28dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap28dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                2 ** 12,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap28dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap28dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                0,
                2 ** 12,
                0,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap60dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap60dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                0,
                0,
                2 ** 12,
                0,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap60dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap60dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                0,
                0,
                0,
                2 ** 12,
                0,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap90dPayFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap90dPayFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                0,
                0,
                0,
                0,
                2 ** 12,
                0
            )
        );
    }

    function testShouldRevertWhenFixedRateCap90dReceiveFixedToBig() public {
        // given
        MockTestnetToken randomStable = new MockTestnetToken(
            "Random Stable",
            "SandomStable",
            100_000_000 * 1e18,
            uint8(18)
        );
        bool assetSupportedBefore = _iporRiskManagementOracle.isAssetSupported(address(randomStable));

        BaseSpreads memory baseSpread;
        FixedRateCaps memory fixedRateCaps;
        // when
        vm.expectRevert("fixedRateCap90dReceiveFixed overflow");
        _iporRiskManagementOracle.addAsset(
            address(randomStable),
            IporRiskManagementOracleTypes.RiskIndicators(
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_90_PER,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
                TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
            ),
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                -type(int24).max + 1,
                type(int24).max - 1,
                0,
                0,
                0,
                0,
                0,
                2 ** 12
            )
        );
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
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor28d
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_28);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 demandSpreadFactor60d
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_60);


        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 demandSpreadFactor90d
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_90);

        assertEq(maxNotionalPayFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxNotionalReceiveFixed, uint256(TestConstants.RMO_NOTIONAL_1B) * 1e22);
        assertEq(maxCollateralRatioPayFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatioReceiveFixed, uint256(TestConstants.RMO_COLLATERAL_RATIO_48_PER) * 1e14);
        assertEq(maxCollateralRatio, uint256(TestConstants.RMO_COLLATERAL_RATIO_90_PER) * 1e14);
        assertEq(lastUpdateTimestamp, _blockTimestamp);
        assertEq(demandSpreadFactor28d, uint256(TestConstants.RMO_DEMAND_SPREAD_FACTOR_28), "demandSpreadFactor28d");
        assertEq(demandSpreadFactor60d, uint256(TestConstants.RMO_DEMAND_SPREAD_FACTOR_60), "demandSpreadFactor60d");
        assertEq(demandSpreadFactor90d, uint256(TestConstants.RMO_DEMAND_SPREAD_FACTOR_90), "demandSpreadFactor90d");
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
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_28);
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
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
        );

        // then
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
        ) = _iporRiskManagementOracle.getRiskIndicators(address(_daiTestnetToken), IporTypes.SwapTenor.DAYS_28);
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
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_28,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_60,
            TestConstants.RMO_DEMAND_SPREAD_FACTOR_90
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
            uint256 daiFixedRateCap60D,

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
            uint256 daiFixedRateCap90D,

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
