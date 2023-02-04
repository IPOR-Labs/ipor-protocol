// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
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
import "../../contracts/mocks/milton/MockCase7MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase8MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/mocks/milton/MockMiltonStorage.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldNotOpenPositionTest is Test, TestCommons, DataUtils, SwapUtils {
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

    function testShouldNotOpenPositionWhenTotalAmountIsTooLow() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 5e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_310");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.ZERO,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsGreaterThanAssetBalance() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_003");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.USER_SUPPLY_10MLN_18DEC + 3,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_313");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed18Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_313");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed18Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_313");
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.D16 + 48374213950104766,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed6Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), 3e16);
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_313");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed6Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), 3e16);
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_313");
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            48374213950069062,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseOne() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 5e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_312");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1000000000000000000000001,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseTwo() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_312");
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            100688870576704582165765,
            TestConstants.PERCENTAGE_3_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
    }

    function testShouldNotOpenPositionWhenLiquidityPoolBalanceIsTooLow() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 1e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_1_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 16 * TestConstants.D17, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        miltonStorageDai.setJoseph(_userOne);
        vm.prank(_userOne);
        miltonStorageDai.subtractLiquidity(20000 * TestConstants.D18);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // when
        vm.expectRevert("IPOR_320");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooLow() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_308");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, 500
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooHigh() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
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
        // when
        vm.expectRevert("IPOR_309");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, 1000000000000000000001
        );
    }

    function testShouldNotOpenPositionWhenUtilizationIsExceeded() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase7MiltonDai mockCase7MiltonDai = getMockCase7MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase7MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase7MiltonDai));
        prepareMilton(mockCase7MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.expectRevert("IPOR_302");
        vm.prank(_userTwo);
        mockCase7MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsLowerThanFee() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase8MiltonDai mockCase8MiltonDai = getMockCase8MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase8MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase8MiltonDai));
        prepareMilton(mockCase8MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.expectRevert("IPOR_311");
        vm.prank(_userTwo);
        mockCase8MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotGetMiltonAccruedBalanceWhenLiquidtyPoolAmountIsTooLow() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 3e16);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase8MiltonDai mockCase8MiltonDai = getMockCase8MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase8MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase8MiltonDai));
        prepareMilton(mockCase8MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        MockMiltonStorage mockMiltonStorage = new MockMiltonStorage();
        mockCase8MiltonDai.setMockMiltonStorage(address(mockMiltonStorage));
        // when
        vm.expectRevert("IPOR_301");
        mockCase8MiltonDai.getAccruedBalance();
    }
}