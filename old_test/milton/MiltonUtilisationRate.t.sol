// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";

import "contracts/amm/AmmStorage.sol";

contract AmmTreasuryUtilisationRateTest is TestCommons, DataUtils, SwapUtils {
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

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE6;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_100_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE6;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_100_000_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE6;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE6;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }
}
