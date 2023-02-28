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
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldClosePositionTest is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
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

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USER_SUPPLY_10MLN_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_COLLATERAL_18DEC
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        vm.stopPrank();
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.TC_400_EMA_18DEC_64UINT);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_400_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;
        uint256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_6DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_COLLATERAL_18DEC
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedPayoffWad));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_400_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_400_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;
        uint256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + TestConstants.TC_COLLATERAL_6DEC;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_6DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_COLLATERAL_18DEC
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))
            + _usdtMockedToken.balanceOf(_userTwo) + _usdtMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedPayoffWad));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 7918994164764269383465;
        expectedBalances.expectedIncomeFeeValue = 791899416476426938347;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.LEVERAGE_18DEC + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity6DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 341335955;
        int256 expectedPayoffWad = -341335955377770264707;
        uint256 expectedPayoffWadAbs = 341335955377770264707;
        expectedBalances.expectedIncomeFeeValue = 34133595537777026471;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_6DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, expectedPayoffWad);
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429745;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USER_SUPPLY_10MLN_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429745;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT
            * Constants.D18_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            - expectedBalances.expectedPayoffAbs + TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity6DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_6DEC;
        int256 expectedPayoffWad = TestConstants.TC_COLLATERAL_18DEC_INT;
        expectedBalances.expectedIncomeFeeValue = 996700990;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC - TestConstants.TC_COLLATERAL_6DEC
            + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_6DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, expectedPayoffWad);
        assertEq(actualIncomeFeeValue, TestConstants.TC_INCOME_TAX_18DEC);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, TestConstants.TC_INCOME_TAX_18DEC);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 7782459782613161235257;
        expectedBalances.expectedIncomeFeeValue = 778245978261316123526;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity6DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_3_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 204801573;
        int256 expectedPayoffWad = 204801573226662097384;
        expectedBalances.expectedIncomeFeeValue = 20480157;
        uint256 expectedIncomeFeeValueWad = 20480157322666209738;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedBalances.expectedPayoffAbs
            + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_6DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - uint256(expectedPayoffWad);
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, expectedPayoffWad);
        assertEq(actualIncomeFeeValue, expectedIncomeFeeValueWad);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedIncomeFeeValueWad);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.startPrank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6007512814648756073133;
        expectedBalances.expectedIncomeFeeValue = 600751281464875607313;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6007512814648756073133;
        expectedBalances.expectedIncomeFeeValue = 600751281464875607313;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_151_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336652531;
        expectedBalances.expectedIncomeFeeValue = 989874270595533665253;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_151_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_150_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_151_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336727624;
        expectedBalances.expectedIncomeFeeValue = 989874270595533672762;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 8803281846496279452160;
        expectedBalances.expectedIncomeFeeValue = 880328184649627945216;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_161_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 379451803728287931809;
        expectedBalances.expectedIncomeFeeValue = 37945180372828793181;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor6Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_1_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 341335955377770189613;
        expectedBalances.expectedIncomeFeeValue = 34133595537777018961;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor160Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndOwnerAndIpor120Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 7918994164764269327486;
        expectedBalances.expectedIncomeFeeValue = 791899416476426932749;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429746;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_3_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6417115961102080349821;
        expectedBalances.expectedIncomeFeeValue = 641711596110208034982;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_150_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_150_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_151_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_150_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9898742705955336720799;
        expectedBalances.expectedIncomeFeeValue = 989874270595533672080;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_150_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 9967009897030890705472;
        expectedBalances.expectedIncomeFeeValue = 996700989703089070547;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_160_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_159_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 682671910755540429746;
        expectedBalances.expectedIncomeFeeValue = 68267191075554042975;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.TC_COLLATERAL_18DEC;
        expectedBalances.expectedIncomeFeeValue = TestConstants.TC_INCOME_TAX_18DEC;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndNotOwner(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = 6280581578950972257591;
        expectedBalances.expectedIncomeFeeValue = 628058157895097225759;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost;
        expectedBalances.expectedCloserUserBalance =
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.USD_10_000_000_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(endTimestamp, 1);
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, endTimestamp);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances = _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
            + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userThree)), expectedBalances.expectedCloserUserBalance);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculatePayFixedPositionValueSimpleCase1() public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        int256 expectedPayoff = -38229627002310297226;
        // when
        vm.prank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_14_DAYS_IN_SECONDS, 1
        );
        // then
        assertEq(actualPayoff, expectedPayoff);
    }

    function testShouldCloseDAISinglePayFixedPositionUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        uint256[] memory payFixedSwapIds = new uint256[](1);
        payFixedSwapIds[0] = 1;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase3MiltonDai, 1, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        // then
        vm.prank(_userTwo);
        mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swapsPayFixed) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (, IporTypes.IporSwapMemory[] memory swapsReceiveFixed) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(swapsPayFixed.length, 0);
        assertEq(swapsReceiveFixed.length, 0);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCloseDAITwoPayFixedPositionsUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        // then
        vm.prank(_userTwo);
        mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swapsPayFixed) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (, IporTypes.IporSwapMemory[] memory swapsReceiveFixed) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        assertEq(swapsPayFixed.length, 0);
        assertEq(swapsReceiveFixed.length, 0);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
    }

    function testShouldCloseDAISingleReceiveFixedPositionUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](1);
        receiveFixedSwapIds[0] = 1;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase3MiltonDai, 1, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // then
        vm.prank(_userTwo);
        mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swapsPayFixed) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (, IporTypes.IporSwapMemory[] memory swapsReceiveFixed) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(swapsPayFixed.length, 0);
        assertEq(swapsReceiveFixed.length, 0);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCloseDAITwoReceiveFixedPositionsUsingFunctionWithArray18DecimalsAndOwner() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase3MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_userTwo);
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;
        // then
        mockCase3MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldClosePositionByOwnerWhenPayFixedAndSingleIdWithEmergencyFunction() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsPayFixed(
            _userTwo,
            mockCase3MiltonDai,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_admin);
        mockCase3MiltonDai.pause();
        uint256[] memory payFixedSwapIds = new uint256[](1);
        payFixedSwapIds[0] = 1;
        // then
        vm.prank(_admin);
        mockCase3MiltonDai.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldClosePositionByOwnerWhenPayFixedAndMultipleIDsWithEmergencyFunction() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsPayFixed(
            _userTwo,
            mockCase3MiltonDai,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_admin);
        mockCase3MiltonDai.pause();
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        // then
        vm.prank(_admin);
        mockCase3MiltonDai.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldClosePositionByOwnerWhenReceiveFixedAndSingleIdWithEmergencyFunction() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            mockCase3MiltonDai,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_admin);
        mockCase3MiltonDai.pause();
        uint256[] memory receiveFixedSwaps = new uint256[](1);
        receiveFixedSwaps[0] = 1;
        // then
        vm.prank(_admin);
        mockCase3MiltonDai.emergencyCloseSwapsReceiveFixed(receiveFixedSwaps);
    }

    function testShouldClosePositionByOwnerWhenReceiveFixedAndMultipleIDsWithEmergencyFunction() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            mockCase3MiltonDai,
            2,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.startPrank(_admin);
        mockCase3MiltonDai.pause();
        uint256[] memory receiveFixedSwaps = new uint256[](2);
        receiveFixedSwaps[0] = 1;
        receiveFixedSwaps[1] = 2;
        // then
        mockCase3MiltonDai.emergencyCloseSwapsReceiveFixed(receiveFixedSwaps);
        vm.stopPrank();
    }

    function testShouldOnlyCloseFirstPosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        assertEq(1, swaps.length);
        assertEq(swaps[0].id, 2);
    }

    function testShouldOnlyCloseLastPosition() public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_9_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        assertEq(1, swaps.length);
        assertEq(swaps[0].id, 1);
    }

    function testShouldClosePositionWithAppropriateBalanceDAIWhenOwnerAndPayFixedAndMiltonLostAndUserEarnedLessThanCollateralAfterMaturityAndIPORIndexCalculatedBeforeClose(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_120_EMA_18DEC_64UINT);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS - 1
        );
        vm.stopPrank();
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.SPECIFIC_INTEREST_AMOUNT_CASE_1;
        expectedBalances.expectedIncomeFeeValue = TestConstants.SPECIFIC_INCOME_TAX_CASE_1;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - int256(expectedBalances.expectedPayoffAbs) + int256(expectedBalances.expectedIncomeFeeValue);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC
            - expectedBalances.expectedPayoffAbs + expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC - expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        vm.startPrank(_userTwo);
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // when
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        vm.stopPrank();
        // then
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIReceiveFixedWithEmergencyFunctionMultipleIDsWhenContractIsPaused() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            mockCase3MiltonDai,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.startPrank(_admin);
        mockCase3MiltonDai.pause();
        uint256[] memory receiveFixedSwapIds = new uint256[](1);
        receiveFixedSwapIds[0] = 1;
        mockCase3MiltonDai.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
        vm.stopPrank();
    }

    function testShouldTransferAllLiquidationDepositsInASingleTransferToLiquidatorWhenPayFixed() public {
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 2;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        // when
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(mockCase0MiltonDai), address(_userThree), 40 * TestConstants.D18);
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldTransferAllLiquidationDepositsInASingleTransferToLiquidatorWhenReceiveFixed() public {
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 2;
        uint256[] memory payFixedSwapIds = new uint256[](0);
        // when
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(mockCase0MiltonDai), address(_userThree), 40 * TestConstants.D18);
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldCloseTwoPayFixedPositionsUsingFunctionWithArrayWhenOneOfThemIsNotValid() public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 300;
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        // then
        vm.prank(_userTwo);
        mockCase0MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldCloseTwoReceiveFixedPositionsUsingFunctionWithArrayWhenOneOfThemIsNotValid() public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonDai, 2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.LEVERAGE_18DEC
        );
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 1;
        receiveFixedSwapIds[1] = 300; // wrong id
        uint256[] memory payFixedSwapIds = new uint256[](0);
        // then
        vm.prank(_userTwo);
        mockCase0MiltonDai.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldClose10PayFixedAnd10ReceiveFixedPositionsInOneTransactionCaseOne() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        uint256[] memory payFixedSwapIds = new uint256[](10);
        uint256[] memory receiveFixedSwapIds = new uint256[](10);
        for (uint256 i = 0; i < 10; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 10; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 1;
        }
        vm.prank(_userTwo);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        for (uint256 i = 0; i < 10; ++i) {
            IporTypes.IporSwapMemory memory payFixedSwap = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(payFixedSwap.state, TestConstants.ZERO);
        }
        for (uint256 i = 0; i < 10; ++i) {
            IporTypes.IporSwapMemory memory receiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(receiveFixedSwap.state, TestConstants.ZERO);
        }
    }

    function testShouldClose5PayFixedAnd5ReceiveFixedPositionsInOneTransactionCase2SomeAreAlreadyClosed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);
        // when
        uint256[] memory payFixedSwapIds = new uint256[](5);
        uint256[] memory receiveFixedSwapIds = new uint256[](5);
        for (uint256 i = 0; i < 5; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 5; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 1;
        }
        vm.startPrank(_userTwo);
        mockCase3MiltonDai.itfCloseSwapPayFixed(3, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(8, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        vm.stopPrank();
        // then
        for (uint256 i = 0; i < 5; ++i) {
            IporTypes.IporSwapMemory memory payFixedSwap = miltonStorageDai.getSwapPayFixed(i + 1);
            assertEq(payFixedSwap.state, TestConstants.ZERO);
        }
        for (uint256 i = 0; i < 5; ++i) {
            IporTypes.IporSwapMemory memory receiveFixedSwap = miltonStorageDai.getSwapReceiveFixed(i + 1);
            assertEq(receiveFixedSwap.state, TestConstants.ZERO);
        }
    }

    function testShouldClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionCase4MixedLiquidators() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 3;
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 2;
        receiveFixedSwapIds[1] = 4;
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapReceiveFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        IporTypes.IporSwapMemory memory payFixedSwapOne = miltonStorageDai.getSwapPayFixed(1);
        IporTypes.IporSwapMemory memory receiveFixedSwapTwo = miltonStorageDai.getSwapReceiveFixed(2);
        IporTypes.IporSwapMemory memory payFixedSwapThree = miltonStorageDai.getSwapPayFixed(3);
        IporTypes.IporSwapMemory memory receiveFixedSwapFour = miltonStorageDai.getSwapReceiveFixed(4);
        assertEq(payFixedSwapOne.state, TestConstants.ZERO);
        assertEq(receiveFixedSwapTwo.state, TestConstants.ZERO);
        assertEq(payFixedSwapThree.state, TestConstants.ZERO);
        assertEq(receiveFixedSwapFour.state, TestConstants.ZERO);
        assertEq(_daiMockedToken.balanceOf(address(_userTwo)), 9999704642032047919907479);
        assertEq(_daiMockedToken.balanceOf(address(_userThree)), 9999784642032047919907479);
    }

    function testShouldNotClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionCase5MixedLiquidatorsOwnerAndNotOwnerBeforeMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](2);
        payFixedSwapIds[0] = 1;
        payFixedSwapIds[1] = 3;
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        receiveFixedSwapIds[0] = 2;
        receiveFixedSwapIds[1] = 4;
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        openSwapReceiveFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        // when
        vm.expectRevert("IPOR_321");
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldNotClose12PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenLiquidationLegLimitExceeded()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(14 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](12);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        for (uint256 i = 0; i < 12; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 2; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 1;
        }
        // when
        vm.expectRevert("IPOR_315");
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldNotClose2PayFixedAnd12ReceiveFixedPositionsInOneTransactionWhenLiquidationLegLimitExceeded()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(14 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](2);
        uint256[] memory receiveFixedSwapIds = new uint256[](12);
        for (uint256 i = 0; i < 2; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 12; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 1;
        }
        // when
        vm.expectRevert("IPOR_315");
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldClose10PayFixedAnd10ReceiveFixedPositionsInOneTransactionWhenVerifyBalances() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](10);
        uint256[] memory receiveFixedSwapIds = new uint256[](10);
        for (uint256 i = 0; i < 10; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 10; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 10 + 1;
        }
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        assertEq(
            _daiMockedToken.balanceOf(address(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC + 20 * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
        assertEq(_daiMockedToken.balanceOf(address(_userTwo)), 9997046420320479199074790);
    }

    function testShouldClose2PayFixedAnd0ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](10);
        uint256[] memory receiveFixedSwapIds = new uint256[](10);
        for (uint256 i = 0; i < 10; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 10; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 10 + 1;
        }
        for (uint256 i = 10; i < 20; ++i) {
            vm.prank(_userTwo);
            mockCase3MiltonDai.itfCloseSwapReceiveFixed(
                i + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
            );
        }
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        assertEq(
            _daiMockedToken.balanceOf(address(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC + 10 * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
        assertEq(
            _daiMockedToken.balanceOf(address(_userTwo)),
            9997046420320479199074790 + 10 * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
    }

    function testShouldClose0PayFixedAnd2ReceiveFixedPositionsInOneTransactionWhenAllReceiveFixedPositionsAreAlreadyClosed(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(20 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](10);
        uint256[] memory receiveFixedSwapIds = new uint256[](10);
        for (uint256 i = 0; i < 10; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 10; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 10 + 1;
        }
        for (uint256 i = 0; i < 10; ++i) {
            vm.prank(_userTwo);
            mockCase3MiltonDai.itfCloseSwapPayFixed(i + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        }
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        assertEq(
            _daiMockedToken.balanceOf(address(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC + 10 * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
        assertEq(
            _daiMockedToken.balanceOf(address(_userTwo)),
            9997046420320479199074790 + 10 * TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );
    }

    function testShouldCommitTransactionWhenTryToClose2PayFixedAnd2ReceiveFixedPositionsInOneTransactionAndAllPositionsAreAlreadyClosed(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](2);
        uint256[] memory receiveFixedSwapIds = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            openSwapPayFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            payFixedSwapIds[i] = i + 1;
        }
        for (uint256 i = 0; i < 2; ++i) {
            openSwapReceiveFixed(
                _userTwo,
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.PERCENTAGE_1_18DEC,
                TestConstants.LEVERAGE_18DEC,
                mockCase3MiltonDai
            );
            receiveFixedSwapIds[i] = i + 2 + 1;
        }
        for (uint256 i = 0; i < 2; ++i) {
            vm.prank(_userTwo);
            mockCase3MiltonDai.itfCloseSwapPayFixed(i + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        }
        for (uint256 i = 0; i < 2; ++i) {
            vm.prank(_userTwo);
            mockCase3MiltonDai.itfCloseSwapReceiveFixed(
                i + 2 + 1, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
            );
        }
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        assertEq(_daiMockedToken.balanceOf(address(_userThree)), TestConstants.USER_SUPPLY_10MLN_18DEC);
        assertEq(_daiMockedToken.balanceOf(address(_userTwo)), 9999489284064095839814958);
    }

    function testShouldCommitTransactionEvenWhenListsForClosingSwapsAreEmpty() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMilton(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(4 * TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256[] memory payFixedSwapIds = new uint256[](0);
        uint256[] memory receiveFixedSwapIds = new uint256[](0);
        // when
        vm.prank(_userThree);
        mockCase3MiltonDai.itfCloseSwaps(
            payFixedSwapIds, receiveFixedSwapIds, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS
        );
        // then
        // no errors during execution closeSwaps
    }
}
