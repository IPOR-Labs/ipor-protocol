// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "test/TestCommons.sol";
import "../utils/TestConstants.sol";

import "contracts/amm/AmmStorage.sol";

contract AmmCollateralRatioTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsNotExceededAndDefaultCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsNotExceededAndDefaultCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),  1)
        );
        vm.stopPrank();
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsNotExceededAndCustomCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsNotExceededAndCustomCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        // when
        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),  1)
        );
        vm.stopPrank();
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsExceededAndDefaultCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsExceededAndCustomCollateralRatio()
        public
    {
        // given
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 800000000000000000,
            maxCollateralRatioPerLeg: 300000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });


        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsExceededAndDefaultCollateralRatio()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 800000000000000000,
            maxCollateralRatioPerLeg: 300000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });


        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.expectRevert("IPOR_303");
        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
        vm.stopPrank();
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolCollateralRatioPerLegIsExceededAndCustomCollateralRatio()
        public
    {
        // given
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 800000000000000000,
            maxCollateralRatioPerLeg: 300000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });


        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        // when
        vm.expectRevert("IPOR_303");
        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
        vm.stopPrank();
    }
}
