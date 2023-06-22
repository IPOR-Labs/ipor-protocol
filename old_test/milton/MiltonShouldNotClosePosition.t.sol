// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@ipor-protocol/test/TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/test/mocks/spread/MockSpreadModel.sol";

contract AmmTreasuryShouldNotClosePositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    event Transfer(address indexed from, address indexed to, uint256 value);

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

        _cfg.spreadImplementation = address(
            new MockSpreadModel(TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT)
        );
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndAmmTreasuryLostAndUserEarnedLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndAmmTreasuryLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndAmmTreasuryEarnedAndUserLostLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndAmmTreasuryLostAndUserEarnedLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndAmmTreasuryLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndAmmTreasuryEarnedAndUserLostLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedWhenIncorrectSwapId() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.expectRevert("IPOR_306");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(TestConstants.ZERO, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedWhenIncorrectStatus() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammTreasury.addSwapLiquidator(_userThree);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
        vm.expectRevert("IPOR_307");
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
        vm.stopPrank();
    }

    function testShouldNotClosePositionReceiveFixedWhenIncorrectStatus() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfOpenSwapReceiveFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammTreasury.addSwapLiquidator(_userThree);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);

        vm.expectRevert("IPOR_307");
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();
    }

    function testShouldNotClosepositionWhenSwapDoesNotExist() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        //        _cfg.ammTreasuryImplementation = address(new _iporProtocol.ammTreasury());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.expectRevert("IPOR_306");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(TestConstants.ZERO, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedSingleIdFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.closeSwapPayFixed(1);
    }

    function testShouldNotClosePositionsPayFixedMultipleIdsFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        uint256[] memory receiveFixedSwapIds;

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedSingleIdFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.closeSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedMultipleIdsFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.ZERO,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        uint256[] memory payFixedSwapIds;

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldNotClosePositionsPayFixedMultipleIdsWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldNotClosePositionPayFixedSingleIdWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.emergencyCloseSwapPayFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedMultipleIdsWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedSingleIdWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.emergencyCloseSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionsByOwnerPayFixedMultipleIdsFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.ammTreasury.openSwapPayFixed(
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.ammTreasury.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldNotClosePositionByOwnerPayFixedSingleIdFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.ammTreasury.emergencyCloseSwapPayFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedByOwnerMultipleIdsFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;
        prepareApproveForUsersDai(
            _users,
            _iporProtocol.asset,
            address(_iporProtocol.joseph),
            address(_iporProtocol.ammTreasury)
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.ammTreasury.openSwapReceiveFixed(
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.ZERO,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.ammTreasury.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedByOwnerSingleIdFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_1_000_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.ammTreasury.emergencyCloseSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionDAIWhenERC20AmountExceedsAmmTreasuryBalanceOnDAIToken() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        deal(address(_iporProtocol.asset), address(_iporProtocol.ammTreasury), 6044629100000000000000000);
        uint256 ammTreasuryDaiBalanceAfterOpen = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        vm.prank(address(_iporProtocol.ammTreasury));
        _iporProtocol.asset.transfer(_admin, ammTreasuryDaiBalanceAfterOpen);

        // when
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
    }
}
