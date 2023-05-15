// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/builder/BuilderUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCaseBaseStanley.sol";
import "../../contracts/mocks/milton/MockCase2Milton18D.sol";
import "../../contracts/mocks/milton/MockCase3Milton18D.sol";

contract MiltonShouldCalculateTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

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
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE2;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _iporProtocol.asset.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE2;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _iporProtocol.asset.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE2;
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

        expectedBalances.expectedPayoffAbs = 7919547282269286005594;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;

        expectedBalances.expectedAdminBalance =
            _iporProtocol.asset.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        // openerUser
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        vm.prank(_userThree);
        // closerUser
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonEarnsAndUserLosesAndDepositIsLowerThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE2;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
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
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _iporProtocol.asset.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
            TestConstants.ZERO_INT -
            openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _iporProtocol.asset.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
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
        expectedBalances.expectedPayoffAbs = 7919547282269286005594;
        //
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedMiltonBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndMiltonEarnsAndUserLosesAndDepositIsLowerThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
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
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT +
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
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = _iporProtocol.milton.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.miltonStorage.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol.miltonStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }
}
