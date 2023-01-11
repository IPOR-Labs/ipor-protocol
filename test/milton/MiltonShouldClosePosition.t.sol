// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
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
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldClosePositionTest is
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
            TestConstants.PERCENTAGE_6_18DEC, // 6%
            TestConstants.PERCENTAGE_4_18DEC, // 4%
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

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC); // 161%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
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
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC); // 161%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(400 * 10 ** 16); // 400%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 160 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + 9967009897; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoffWad
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)),
            TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + 9967009897
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
                - openerUserLost
        ); // USD_10_000_000_6DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
        assertEq(
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_400_18DEC); // 400%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 160 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
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
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); //
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + 9967009897; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoffWad
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)),
            TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + 9967009897
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_6DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_6DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
        assertEq(
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC + TestConstants.USD_10_000_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo)
                + _usdtMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC); // 121%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 7918994164764269383465; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -7918994164764269383465); // expectedPayoff
        assertEq(actualIncomeFeeValue, 791899416476426938347); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.LEVERAGE_18DEC + 7918994164764269383465
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 7918994164764269383465
                - 791899416476426938347
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 791899416476426938347);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC); // 10%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 120 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            + 341335955; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -341335955377770264707); // expectedPayoffWad
        assertEq(actualIncomeFeeValue, 34133595537777026471); // expectedIncomeFeeValue
        assertEq(
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)),
            TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC + 341335955
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
                - openerUserLost
        ); // USD_10_000_000_6DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 341335955377770264707
                - 34133595537777026471
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 34133595537777026471); // expectedIncomeFeeValueWad
        assertEq(
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC); // 10%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 682671910755540429745; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -682671910755540429745); // expectedPayoff
        assertEq(actualIncomeFeeValue, 68267191075554042975); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 682671910755540429745
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 682671910755540429745
                - 68267191075554042975
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 68267191075554042975);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_10_18DEC); // 10%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 682671910755540429745; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -682671910755540429745); // expectedPayoff
        assertEq(actualIncomeFeeValue, 68267191075554042975); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 682671910755540429745
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT * Constants.D18_INT + TestConstants.ZERO_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 682671910755540429745
                - 68267191075554042975
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 68267191075554042975);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC - 9967009897030890732780 + TestConstants.TC_OPENING_FEE_18DEC
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWadAbs + TC_OPENING_FEE_18DEC
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 5 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            - 9967009897 + 996700990; // TC_OPENING_FEE_6DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoffWad
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValueWad
        assertEq(
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)),
            TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC - 9967009897 + 996700990
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
        assertEq(
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 7782459782613161235257 + 778245978261316123526; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 7782459782613161235257); // expectedPayoff
        assertEq(actualIncomeFeeValue, 778245978261316123526); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 7782459782613161235257 + 778245978261316123526
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 7782459782613161235257
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWadAbs + TC_OPENING_FEE_18DEC
        assertEq(balance.treasury, 778245978261316123526);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_3_18DEC); // 3%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 5 * 10 ** 16);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            _admin,
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMiltonStorage(
            miltonStorageUsdt, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt)
        );
        prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
        prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_6DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
            - 204801573 + 20480157; // TC_OPENING_FEE_6DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 204801573226662097384); // expectedPayoffWad
        assertEq(actualIncomeFeeValue, 20480157322666209738); // expectedIncomeFeeValueWad
        assertEq(
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)),
            TestConstants.USD_28_000_6DEC + TestConstants.TC_OPENING_FEE_6DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_6DEC - 204801573 + 20480157
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_usdtMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_6DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT
                - openerUserLost
        ); // USD_10_000_000_6DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 204801573226662097384
        ); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC - expectedPayoffWadAbs
        assertEq(balance.treasury, 20480157322666209738); // expectedIncomeFeeValueWad
        assertEq(
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 6007512814648756073133 + 600751281464875607313; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 6007512814648756073133); // expectedPayoff
        assertEq(actualIncomeFeeValue, 600751281464875607313); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 6007512814648756073133 + 600751281464875607313
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 6007512814648756073133
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 600751281464875607313);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 6007512814648756073133 + 600751281464875607313; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 6007512814648756073133); // expectedPayoff
        assertEq(actualIncomeFeeValue, 600751281464875607313); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 6007512814648756073133 + 600751281464875607313
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 6007512814648756073133
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 600751281464875607313);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedBetween99And100PercentOfCollateralAfterBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9898742705955336652531 + 989874270595533665253; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9898742705955336652531); // expectedPayoff
        assertEq(actualIncomeFeeValue, 989874270595533665253); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9898742705955336652531 + 989874270595533665253
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9898742705955336652531
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 989874270595533665253);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_151_18DEC); // 151%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 150 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9898742705955336727624; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9898742705955336727624); // expectedPayoff
        assertEq(actualIncomeFeeValue, 989874270595533672762); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9898742705955336727624
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + 20 * Constants.D18_INT - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9898742705955336727624
                - 989874270595533672762
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 989874270595533672762);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC); // 121%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 8803281846496279452160; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(
            _userTwo, block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS, mockCase0MiltonDai
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -8803281846496279452160); // expectedPayoff
        assertEq(actualIncomeFeeValue, 880328184649627945216); // expectedIncomeFeeValueWad
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 8803281846496279452160
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 8803281846496279452160
                - 880328184649627945216
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 880328184649627945216);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_161_18DEC); // 161%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_10_18DEC); // 10%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 379451803728287931809 + 37945180372828793181; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS, 1
        );
        vm.prank(_userThree); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(
            1, block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS
        );
        vm.prank(_userThree); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(
            _userTwo, block.timestamp + TestConstants.PERIOD_27_DAYS_19_HOURS_IN_SECONDS, mockCase0MiltonDai
        );
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 379451803728287931809); // expectedPayoff
        assertEq(actualIncomeFeeValue, 37945180372828793181); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 379451803728287931809 + 37945180372828793181
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.ZERO_INT - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(
            int256(_daiMockedToken.balanceOf(_userThree)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - TestConstants.ZERO_INT
        ); // USD_10_000_000_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 379451803728287931809
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 37945180372828793181);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC
                + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
                + _daiMockedToken.balanceOf(_userThree)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC); // 159%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor6Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_1_18DEC); // 1%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 341335955377770189613; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -341335955377770189613); // expectedPayoff
        assertEq(actualIncomeFeeValue, 34133595537777018961); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 341335955377770189613
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 341335955377770189613
                - 34133595537777018961
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 34133595537777018961);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor160Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 9967009897030890732780; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 9967009897030890732780
                - 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor120Percent(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC); // 4%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + 7918994164764269327486; // TC_OPENING_FEE_18DEC_int + TC_IPOR_PUBLICATION_AMOUNT_18DEC_int + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_int + expectedPayoffAbs
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, -7918994164764269327486); // expectedPayoff
        assertEq(actualIncomeFeeValue, 791899416476426932749); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC + 7918994164764269327486
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC + 7918994164764269327486
                - 791899416476426932749
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
        assertEq(balance.treasury, 791899416476426932749);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses(
    ) public {
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_159_18DEC); // 159%
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160 * 10 ** 16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
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
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC_INT + TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - expectedPayoffAbs + expectedIncomeFeeValue
        // when
        vm.prank(_userTwo); // openerUser
        int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 1
        );
        vm.prank(_userTwo); // closerUser
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userTwo); // closerUser
        uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
        assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC
                + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC - 9967009897030890732780 + 996700989703089073278
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
        assertEq(
            int256(_daiMockedToken.balanceOf(_userTwo)),
            TestConstants.USD_10_000_000_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
                - openerUserLost
        ); // USD_10_000_000_18DEC_INT + openerUserEarned - openerUserLost
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(
            balance.liquidityPool,
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.TC_OPENING_FEE_18DEC - 9967009897030890732780
        ); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC - expectedPayoffWadAbs
        assertEq(balance.treasury, 996700989703089073278);
        assertEq(
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo)
        ); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
        assertEq(soap, TestConstants.ZERO_INT);
    }
}
