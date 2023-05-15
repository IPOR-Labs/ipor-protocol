// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldClosePositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    struct ActualBalances {
        uint256 actualSumOfBalances;
        uint256 actualMiltonBalance;
        int256 actualPayoff;
        int256 actualOpenerUserBalance;
        int256 actualCloserUserBalance;
    }

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
            new MockSpreadModel(
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndOwner()
        public
    {
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.TC_400_EMA_18DEC_64UINT);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_400_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;

        uint256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_OPENING_FEE_6DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedPayoffWad));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndNotOwner()
        public
    {
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_400_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_400_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;

        uint256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_OPENING_FEE_6DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
            TestConstants.TC_COLLATERAL_6DEC;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedPayoffWad));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 8803896728789356263759;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.LEVERAGE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity6DecimalsAndOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 379478307;
        int256 expectedPayoffWad = -379478307275403311621;
        uint256 expectedPayoffWadAbs = 379478307275403311621;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_OPENING_FEE_6DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedPayoffWadAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, expectedPayoffWad);
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682719593299076345445;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682719593299076345445;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT *
            Constants.D18_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity6DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;
        int256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC_INT;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_OPENING_FEE_6DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC -
            TestConstants.TC_COLLATERAL_6DEC;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length, "incorrect swaps length");
        assertEq(actualBalances.actualPayoff, expectedPayoffWad, "incorrect payoff");

        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout,
            "incorrect sum of balances"
        );
        assertEq(
            actualBalances.actualMiltonBalance,
            expectedBalances.expectedMiltonBalance,
            "incorrect milton balance"
        );
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance,
            "incorrect opener user balance"
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO, "incorrect total collateral pay fixed");
        assertEq(
            balance.iporPublicationFee,
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
            "incorrect ipor publication fee"
        );
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance, "incorrect liquidity pool");
        assertEq(soap, TestConstants.ZERO_INT, "incorrect soap");
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity18DecimalsAndOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 8626162061333830010575;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity6DecimalsAndOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 227686985;
        int256 expectedPayoffWad = 227686984365242020835;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC +
            TestConstants.TC_OPENING_FEE_6DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            uint256(expectedPayoffWad);
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC +
            TestConstants.USD_10_000_000_6DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length, "swaps length");
        assertEq(actualBalances.actualPayoff, expectedPayoffWad, "incorrect payoff");

        assertEq(
            actualBalances.actualSumOfBalances,
            expectedBalances.expectedSumOfBalancesBeforePayout,
            "incorrect sum of balances"
        );
        assertEq(
            actualBalances.actualMiltonBalance,
            expectedBalances.expectedMiltonBalance,
            "incorrect milton balance"
        );
        assertEq(
            actualBalances.actualOpenerUserBalance,
            expectedBalances.expectedOpenerUserBalance,
            "incorrect opener user balance"
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO, "incorrect total collateral pay fixed");
        assertEq(
            balance.iporPublicationFee,
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
            "incorrect ipor publication fee"
        );
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance, "incorrect liquidity pool");
        assertEq(soap, TestConstants.ZERO_INT, "incorrect soap");
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree); // closerUser
        _iporProtocol.milton.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1
        );

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6007932421031872131299;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6007932421031872131299;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree); // closerUser
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralOneHourBeforeMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 381754039253066849932;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_23_HOURS_IN_SECONDS;

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);

        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor6Percent()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 378340441286571471689;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor160Percent()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor120Percent()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 8777498237848458607443;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));

        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 682719593299076345445;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;

        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6417564177011317957409;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_150_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree); // closerUser
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 682719593299076345445;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndNotOwner()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 6281020258351502682039;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            20 *
            Constants.D18_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC +
            TestConstants.USD_10_000_000_18DEC;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        actualBalances.actualSumOfBalances =
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        actualBalances.actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        actualBalances.actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));
        actualBalances.actualCloserUserBalance = int256(_iporProtocol.asset.balanceOf(_userThree));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(actualBalances.actualCloserUserBalance, expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculatePayFixedPositionValueSimpleCase1() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedPayoff = -38232297224748308509;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_14_DAYS_IN_SECONDS,
            1
        );

        // then
        assertEq(actualPayoff, expectedPayoff);
    }

    function testShouldCloseDAISinglePayFixedPositionUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.warp(100);

        uint256[] memory payFixedSwapIds = new uint256[](1);
        payFixedSwapIds[0] = 1;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
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

        vm.warp(100 + TestConstants.PERIOD_28_DAYS_IN_SECONDS);

        //when
        vm.prank(_userTwo);
        (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);

        // then
        assertEq(closedPayFixedSwaps.length, 1);
        assertEq(closedReceiveFixedSwaps.length, TestConstants.ZERO);
        assertTrue(closedPayFixedSwaps[0].closed);
    }

    function testShouldCloseDAITwoPayFixedPositionsUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.warp(100);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        vm.warp(100 + TestConstants.PERIOD_28_DAYS_IN_SECONDS);

        // when
        vm.prank(_userTwo);
        (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);

        // then
        assertEq(closedPayFixedSwaps.length, 2);
        assertEq(closedReceiveFixedSwaps.length, TestConstants.ZERO);
        assertTrue(closedPayFixedSwaps[0].closed);
        assertTrue(closedPayFixedSwaps[1].closed);
    }

    function testShouldCloseDAISingleReceiveFixedPositionUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.warp(100);

        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](1);
        receiveFixedSwapIds[0] = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(100 + TestConstants.PERIOD_28_DAYS_IN_SECONDS);

        // when
        vm.prank(_userTwo);
        (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);

        //then
        assertEq(closedPayFixedSwaps.length, TestConstants.ZERO);
        assertEq(closedReceiveFixedSwaps.length, 1);
        assertTrue(closedReceiveFixedSwaps[0].closed);
    }

    function testShouldCloseDAITwoReceiveFixedPositionsUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;

        // then
        _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldClosePositionByOwnerWhenPayFixedAndSingleIdWithEmergencyFunctionDAIAndContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE7;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        // when
        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapPayFixed(1);
    }

    function testShouldClosePositionByOwnerWhenPayFixedAndMultipleIDsWithEmergencyFunctionAndContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE7;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        // when
        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_admin);
        _iporProtocol.milton.pause();

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;

        // then
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldClosePositionByOwnerWhenReceiveFixedAndSingleIdWithEmergencyFunctionAndContractIsPaused()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE7;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapReceiveFixed(1);
    }

    function testShouldClosePositionByOwnerWhenReceiveFixedAndMultipleIDsWithEmergencyFunction() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE7;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.startPrank(_admin);
        _iporProtocol.milton.pause();
        uint256[] memory receiveFixedSwaps = new uint256[](2);
        receiveFixedSwaps[0] = 1;
        receiveFixedSwaps[1] = 2;

        // then
        _iporProtocol.milton.emergencyCloseSwapsReceiveFixed(receiveFixedSwaps);
        vm.stopPrank();
    }

    function testShouldOnlyCloseFirstPosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        assertEq(1, swaps.length);
        assertEq(swaps[0].id, 2);
    }

    function testShouldOnlyCloseLastPosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        assertEq(1, swaps.length);
        assertEq(swaps[0].id, 1);
    }

    function testShouldClosePositionWithAppropriateBalanceDAIWhenOwnerAndPayFixedAndMiltonLostAndUserEarnedLessThanCollateralAfterMaturityAndIPORIndexCalculatedBeforeClose()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );
        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS - 1
        );
        vm.stopPrank();

        ExpectedMiltonBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = TestConstants.SPECIFIC_INTEREST_AMOUNT_CASE_1;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC -
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        vm.startPrank(_userTwo);

        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        uint256 actualMiltonBalance = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        int256 actualOpenerUserBalance = int256(_iporProtocol.asset.balanceOf(_userTwo));

        assertEq(TestConstants.ZERO, swaps.length, "incorrect number of swaps");
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs), "incorrect payoff");
        assertEq(actualMiltonBalance, expectedBalances.expectedMiltonBalance, "incorrect milton balance");
        assertEq(actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance, "incorrect opener user balance");
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO, "incorrect total collateral pay fixed");
        assertEq(
            balance.iporPublicationFee,
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
            "incorrect ipor publication fee"
        );
        assertEq(
            balance.liquidityPool,
            expectedBalances.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance"
        );
        assertEq(
            expectedBalances.expectedSumOfBalancesBeforePayout,
            actualSumOfBalances,
            "incorrect sum of balances before payout"
        );
        assertEq(soap, TestConstants.ZERO_INT, "incorrect soap");
    }

    function testShouldClosePositionDAIReceiveFixedWithEmergencyFunctionMultipleIDsWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE7;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.startPrank(_admin);
        _iporProtocol.milton.pause();

        uint256[] memory receiveFixedSwapIds = new uint256[](1);
        receiveFixedSwapIds[0] = 1;

        //when
        _iporProtocol.milton.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
        vm.stopPrank();

        //then
    }

    function testShouldTransferAllLiquidationDepositsInASingleTransferToLiquidatorWhenPayFixed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(_iporProtocol.milton), address(_userThree), 40 * TestConstants.D18);

        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldTransferAllLiquidationDepositsInASingleTransferToLiquidatorWhenReceiveFixed() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;
        uint256[] memory payFixedSwapIds = new uint256[](0);

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(_iporProtocol.milton), address(_userThree), 40 * TestConstants.D18);
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldCloseTwoPayFixedPositionsUsingFunctionWithArrayWhenOneOfThemIsNotValid() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.warp(100);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 300;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        //when
        vm.warp(100 + 28 days);
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);

        // then
    }

    function testShouldCloseTwoReceiveFixedPositionsUsingFunctionWithArrayWhenOneOfThemIsNotValid() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.warp(100);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 300; // wrong id
        uint256[] memory payFixedSwapIds = new uint256[](0);

        vm.warp(100 + 28 days);

        //when
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);

        // then
    }

    function testShouldClose10PayFixedAnd10ReceiveFixedPositionsInOneTransactionCaseOne() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        uint256 volumePayFixed = 10;
        uint256 volumeReceiveFixed = 10;
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );
            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        for (uint256 i = 0; i < volumePayFixed; ++i) {
            IporTypes.IporSwapMemory memory payFixedSwap = _iporProtocol.miltonStorage.getSwapPayFixed(i + 1);
            assertEq(payFixedSwap.state, TestConstants.ZERO);
        }
        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            IporTypes.IporSwapMemory memory receiveFixedSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(i + 1);
            assertEq(receiveFixedSwap.state, TestConstants.ZERO);
        }
    }

    function testShouldClose5PayFixedAnd5ReceiveFixedPositionsInOneTransactionCase2SomeAreAlreadyClosed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        uint256 volumePayFixed = 5;
        uint256 volumeReceiveFixed = 5;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(10 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }
        vm.startPrank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(3, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(8, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);

        (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.milton.itfCloseSwaps(
                payFixedSwapIds,
                receiveFixedSwapIds,
                block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
            );
        vm.stopPrank();

        // then
        for (uint256 i = 0; i < volumePayFixed; ++i) {
            IporTypes.IporSwapMemory memory payFixedSwap = _iporProtocol.miltonStorage.getSwapPayFixed(i + 1);
            assertEq(payFixedSwap.state, TestConstants.ZERO);
        }
        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            IporTypes.IporSwapMemory memory receiveFixedSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(i + 1);
            assertEq(receiveFixedSwap.state, TestConstants.ZERO);
        }
        assertTrue(closedPayFixedSwaps[0].closed);
        assertTrue(closedPayFixedSwaps[1].closed);
        assertFalse(closedPayFixedSwaps[2].closed);
        assertTrue(closedPayFixedSwaps[3].closed);
        assertTrue(closedPayFixedSwaps[4].closed);
        assertTrue(closedReceiveFixedSwaps[0].closed);
        assertTrue(closedReceiveFixedSwaps[1].closed);
        assertFalse(closedReceiveFixedSwaps[2].closed);
        assertTrue(closedReceiveFixedSwaps[3].closed);
        assertTrue(closedReceiveFixedSwaps[4].closed);
    }

    function testShouldClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionCase4MixedLiquidators() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 3;

        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 2;
        receiveFixedSwapIds[1] = 4;

        uint256 expectedBalanceUserTwo = 9999782482935434037095601;
        uint256 expectedBalanceUserThree = 9999862482935434037095601;

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userThree);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userThree);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        uint256 actualBalanceUserTwo = _iporProtocol.asset.balanceOf(address(_userTwo));
        uint256 actualBalanceUserThree = _iporProtocol.asset.balanceOf(address(_userThree));
        IporTypes.IporSwapMemory memory payFixedSwapOne = _iporProtocol.miltonStorage.getSwapPayFixed(1);
        IporTypes.IporSwapMemory memory receiveFixedSwapTwo = _iporProtocol.miltonStorage.getSwapReceiveFixed(2);
        IporTypes.IporSwapMemory memory payFixedSwapThree = _iporProtocol.miltonStorage.getSwapPayFixed(3);
        IporTypes.IporSwapMemory memory receiveFixedSwapFour = _iporProtocol.miltonStorage.getSwapReceiveFixed(4);
        assertEq(payFixedSwapOne.state, TestConstants.ZERO);
        assertEq(receiveFixedSwapTwo.state, TestConstants.ZERO);
        assertEq(payFixedSwapThree.state, TestConstants.ZERO);
        assertEq(receiveFixedSwapFour.state, TestConstants.ZERO);
        assertEq(actualBalanceUserTwo, expectedBalanceUserTwo);
        assertEq(actualBalanceUserThree, expectedBalanceUserThree);
    }

    function testShouldNotClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionCase5MixedLiquidatorsOwnerAndNotOwnerBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 3;

        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 2;
        receiveFixedSwapIds[1] = 4;

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userThree);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userThree);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldNotClose12PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenLiquidationLegLimitExceeded()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(14 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256 volumePayFixed = 12;
        uint256 volumeReceiveFixed = 2;
        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.expectRevert("IPOR_315");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldNotClose2PayFixedAnd12ReceiveFixedPositionsInOneTransactionWhenLiquidationLegLimitExceeded()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        uint256 volumePayFixed = 2;
        uint256 volumeReceiveFixed = 12;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(14 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.expectRevert("IPOR_315");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldClose10PayFixedAnd10ReceiveFixedPositionsInOneTransactionWhenVerifyBalances() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_userOne);
        uint256 volumePayFixed = 10;
        uint256 volumeReceiveFixed = 10;
        uint256 expectedBalanceLiquidator = TestConstants.USER_SUPPLY_10MLN_18DEC +
            (volumePayFixed + volumeReceiveFixed) *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        uint256 expectedBalanceTrader = 9997824829354340370956010;

        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(_userThree));
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldClose2PayFixedAnd0ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 volumePayFixed = 10;
        uint256 volumeReceiveFixed = 10;
        uint256 expectedBalanceLiquidator = TestConstants.USER_SUPPLY_10MLN_18DEC +
            volumeReceiveFixed *
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        uint256 expectedBalanceTrader = 9998024829354340370956010;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfCloseSwapReceiveFixed(
                i + 1,
                block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
            );
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);
        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(_userThree));
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator, "incorrect liquidator balance");
        assertEq(actualBalanceTrader, expectedBalanceTrader, "incorrect trader balance");
    }

    function testShouldClose0PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 volumePayFixed = 10;
        uint256 volumeReceiveFixed = 10;
        uint256 expectedBalanceLiquidator = TestConstants.USER_SUPPLY_10MLN_18DEC;
        uint256 expectedBalanceTrader = 9998024829354340370956010;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfCloseSwapPayFixed(i + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(this));
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));

        assertEq(
            actualBalanceLiquidator,
            expectedBalanceLiquidator,
            "actualBalanceLiquidator != expectedBalanceLiquidator"
        );
        assertEq(actualBalanceTrader, expectedBalanceTrader, "actualBalanceTrader != expectedBalanceTrader");
    }

    function testShouldCommitTransactionWhenTryToClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionAndAllPositionsAreAlreadyClosed()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);

        uint256 volumePayFixed = 2;
        uint256 volumeReceiveFixed = 2;
        uint256 expectedBalanceLiquidator = TestConstants.USER_SUPPLY_10MLN_18DEC;

        uint256 expectedBalanceTrader = 9999644965870868074191202;

        uint256[] memory payFixedSwapIds = new uint256[](volumePayFixed);
        uint256[] memory receiveFixedSwapIds = new uint256[](volumeReceiveFixed);

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            payFixedSwapIds[i] = i + 1;
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC
            );

            receiveFixedSwapIds[i - volumePayFixed] = i + 1;
        }

        for (uint256 i = 0; i < volumePayFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfCloseSwapPayFixed(i + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        }

        for (uint256 i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfCloseSwapReceiveFixed(
                i + 1,
                block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
            );
        }

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        uint256 actualBalanceLiquidator = _iporProtocol.asset.balanceOf(address(_userThree));
        uint256 actualBalanceTrader = _iporProtocol.asset.balanceOf(address(_userTwo));
        assertEq(actualBalanceLiquidator, expectedBalanceLiquidator);
        assertEq(actualBalanceTrader, expectedBalanceTrader);
    }

    function testShouldCommitTransactionEvenWhenListsForClosingSwapsAreEmpty() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](0);

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );

        // then
        // no errors during execution closeSwaps
    }

    function testShouldClosePositionDAIWhenAmountExceedsBalanceMiltonOnDAIToken() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _cfg.stanleyImplementation = address(new MockCase0Stanley());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        //        MockCaseBaseStanley(address(_iporProtocol.stanley)).setAsset(address(_iporProtocol.asset));
        uint256 initStanleyBalance = 30000 * TestConstants.D18;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        _iporProtocol.asset.approve(address(_iporProtocol.stanley), TestConstants.USD_1_000_000_000_18DEC);

        MockCaseBaseStanley(address(_iporProtocol.stanley)).forTestDeposit(
            address(_iporProtocol.milton),
            initStanleyBalance
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
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

        deal(address(_iporProtocol.asset), address(_iporProtocol.milton), 6044629100000000000000000);

        uint256 daiBalanceAfterOpen = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));

        vm.prank(address(_iporProtocol.milton));
        _iporProtocol.asset.transfer(_admin, daiBalanceAfterOpen);

        uint256 userTwoBalanceBeforeClose = _iporProtocol.asset.balanceOf(address(_userTwo));
        uint256 stanleyBalanceBeforeClose = _iporProtocol.asset.balanceOf(address(_iporProtocol.stanley));
        uint256 miltonBalanceBeforeClose = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        uint256 userTwoBalanceAfterClose = _iporProtocol.asset.balanceOf(address(_userTwo));
        uint256 stanleyBalanceAfterClose = _iporProtocol.asset.balanceOf(address(_iporProtocol.stanley));
        uint256 miltonBalanceAfterClose = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        assertEq(userTwoBalanceBeforeClose, 9990000 * TestConstants.D18);
        assertEq(userTwoBalanceAfterClose, 10008613868123500345112583);
        assertEq(stanleyBalanceBeforeClose, initStanleyBalance);
        assertLt(stanleyBalanceAfterClose, stanleyBalanceBeforeClose);
        assertEq(miltonBalanceBeforeClose, TestConstants.ZERO);
        assertGt(miltonBalanceAfterClose, TestConstants.ZERO);
    }
}
