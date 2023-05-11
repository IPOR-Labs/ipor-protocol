// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";

contract MiltonShouldCalculateTest is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.PERCENTAGE_2_18DEC,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase2MiltonDai mockCase2MiltonDai = getMockCase2MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase2MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase2MiltonDai)
        );
        prepareMilton(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _daiMockedToken.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        mockCase2MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase2MiltonDai);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_daiMockedToken.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase2MiltonDai mockCase2MiltonDai = getMockCase2MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase2MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase2MiltonDai)
        );
        prepareMilton(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _daiMockedToken.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        mockCase2MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_daiMockedToken.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase2MiltonDai mockCase2MiltonDai = getMockCase2MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase2MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase2MiltonDai)
        );
        prepareMilton(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;

        expectedBalances.expectedAdminBalance =
            _daiMockedToken.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        // openerUser
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        mockCase2MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);

        vm.prank(_userThree);
        // closerUser
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_daiMockedToken.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonEarnsAndUserLosesAndDepositIsLowerThanAbsDifferenceBetweenLegsAfterMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase2MiltonDai mockCase2MiltonDai = getMockCase2MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase2MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase2MiltonDai)
        );
        prepareMilton(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase2MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
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
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _daiMockedToken.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

        mockCase3MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_daiMockedToken.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC -
            expectedBalances.expectedPayoffAbs +
            TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedAdminBalance =
            _daiMockedToken.balanceOf(_admin) +
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        mockCase3MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase3MiltonDai);

        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            expectedBalances.expectedCloserUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
        assertEq(_daiMockedToken.balanceOf(_admin), expectedBalances.expectedAdminBalance);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanAbsDifferenceBetweenLegsBeforeMaturity()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_120_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT -
            openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.TC_OPENING_FEE_18DEC +
            expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
            TestConstants.USER_SUPPLY_10MLN_18DEC;

        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);

        mockCase3MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
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
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_5_EMA_18DEC_64UINT
        );
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase3MiltonDai mockCase3MiltonDai = getMockCase3MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase3MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase3MiltonDai)
        );
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
            block.timestamp
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
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
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) +
            _daiMockedToken.balanceOf(_userTwo) +
            _daiMockedToken.balanceOf(_userThree);
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            50
        );
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            expectedBalances.expectedOpenerUserBalance
        );
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }
}
