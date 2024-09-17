// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "test/TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/builder/BuilderUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "../../contracts/chains/ethereum/amm-old/AmmStorage.sol";
import "test/mocks/spread/MockSpreadModel.sol";

contract AmmTreasuryShouldCalculateTest is TestCommons, DataUtils, SwapUtils {
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

        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndAmmTreasuryLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 682719593299076345445;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndAmmTreasuryLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndAmmTreasuryEarnsAndUserLosesAndDepositIsGreaterThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
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
        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 7919547282269286005594;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        // openerUser
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);

        vm.prank(_userThree);
        // closerUser
        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndAmmTreasuryEarnsAndUserLosesAndDepositIsLowerThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
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
        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndAmmTreasuryLosesAndUserEarnsAndDepositIsGreaterThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;

        expectedBalances.expectedPayoffAbs = 682719593299076345445;

        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndAmmTreasuryLosesAndUserEarnsAndDepositIsLowerThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT -
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_iporProtocol.asset.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndAmmTreasuryEarnsAndUserLosesAndDepositIsGreaterThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 7919547282269286005594;
        //
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);

        expectedBalances.expectedAmmTreasuryBalance =
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

        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndAmmTreasuryEarnsAndUserLosesAndDepositIsLowerThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
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

        ExpectedAmmTreasuryBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT +
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT +
            int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedAmmTreasuryBalance =
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
        uint256 actualSumOfBalances = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) +
            _iporProtocol.asset.balanceOf(_userTwo) +
            _iporProtocol.asset.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = _iporProtocol.ammTreasury.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        _iporProtocol.ammTreasury.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        (, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.ammTreasury);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedBalances.expectedAmmTreasuryBalance);
        assertEq(int256(_iporProtocol.asset.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }
}
