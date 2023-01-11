// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import "../../contracts/interfaces/types/MiltonFacadeTypes.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";

contract MiltonShouldCalculateTest is
    Test,
    TestCommons,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    IporOracleUtils,
    DataUtils,
    SwapUtils,
    StanleyUtils
{
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetTokenUsdt internal _usdtMockedToken;
    MockTestnetTokenUsdc internal _usdcMockedToken;
    MockTestnetTokenDai internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC, // 4%
            TestConstants.PERCENTAGE_2_18DEC, // 2%
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
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegsAfterMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(1 * TestConstants.D17);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase2MiltonDai)
        );
        prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            1 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 682671910755540429746 + 34133595537777021487;
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase2MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 682671910755540429746); // expectedPayoff
        assertEq(actualIncomeFeeValue, 34133595537777021487); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 682671910755540429746 + 34133595537777021487
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC - 682671910755540429746 + TestConstants.TC_OPENING_FEE_18DEC
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC
        assertEq(balance.treasury, 34133595537777021487);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegsBeforeMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase2MiltonDai)
        );
        prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 498350494851544536639; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase2MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 498350494851544536639); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 498350494851544536639
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC - 9967009897030890732780 + TestConstants.TC_OPENING_FEE_18DEC
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC_INT
        assertEq(balance.treasury, 498350494851544536639);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanDifferenceBetweenLegsBeforeMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase2MiltonDai)
        );
        prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 7918994164764269383465; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase2MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -7918994164764269383465); // expectedPayoff
        assertEq(actualIncomeFeeValue, 395949708238213469173); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 7918994164764269383465
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 7918994164764269383465
                - 395949708238213469173
        ); // miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC + expectedPayoffAbs - expectedIncomeFeeValue
        assertEq(balance.treasury, 395949708238213469173);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndMiltonEarnsAndUserLosesAndDepositIsLowerThanDifferenceBetweenLegsAfterMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(4 * 10 ** 16);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase2MiltonDai)
        );
        prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase2MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase2MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase2MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 498350494851544536639); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 498350494851544536639
        ); // miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC + expectedPayoffAbs - expectedIncomeFeeValue
        assertEq(balance.treasury, 498350494851544536639);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase2MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegsAfterMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(10 * 10 ** 16);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase3MiltonDai)
        );
        prepareMockCase3MiltonDai(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 682671910755540429746 + 682671910755540429746; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase3MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 682671910755540429746); // expectedPayoff
        assertEq(actualIncomeFeeValue, 682671910755540429746); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 682671910755540429746 + 682671910755540429746
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC - 682671910755540429746 + TestConstants.TC_OPENING_FEE_18DEC
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC_INT
        assertEq(balance.treasury, 682671910755540429746);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegsBeforeMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase3MiltonDai)
        );
        prepareMockCase3MiltonDai(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase3MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase3MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 9967009897030890732780); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USER_SUPPLY_10MLN_18_DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC - 9967009897030890732780 + TestConstants.TC_OPENING_FEE_18DEC
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC_INT
        assertEq(balance.treasury, 9967009897030890732780);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenPayFixedAndMiltonEarnsAndUserLosesAndDepositIsGreaterThanDifferenceBetweenLegsBeforeMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(121 * 10 ** 16);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 120 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase3MiltonDai)
        );
        prepareMockCase3MiltonDai(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 7918994164764269383465; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase3MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase3MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -7918994164764269383465); // expectedPayoff
        assertEq(actualIncomeFeeValue, 7918994164764269383465); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 7918994164764269383465
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 7918994164764269383465
                - 7918994164764269383465
        ); // miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC + expectedPayoffAbs - expectedIncomeFeeValue
        assertEq(balance.treasury, 7918994164764269383465);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateIncomeFeeOneHundredPercentWhenReceiveFixedAndMiltonEarnsAndUserLosesAndDepositIsLowerThanDifferenceBetweenLegsAfterMaturity(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(4 * 10 ** 16);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(_daiMockedToken), 5 * 10 ** 16);
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
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase3MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase3MiltonDai)
        );
        prepareMockCase3MiltonDai(mockCase3MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai);
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase3MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp);
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase3MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase3MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase3MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase3MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 9967009897030890732780); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USER_SUPPLY_10MLN_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USER_SUPPLY_10MLN_18_DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 9967009897030890732780
        ); // miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC + expectedPayoffAbs - expectedIncomeFeeValue
        assertEq(balance.treasury, 9967009897030890732780);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USER_SUPPLY_10MLN_18DEC
                + TestConstants.USER_SUPPLY_10MLN_18DEC,
            _daiMockedToken.balanceOf(address(mockCase3MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }
}
