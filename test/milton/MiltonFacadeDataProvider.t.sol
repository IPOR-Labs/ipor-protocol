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
import "../../contracts/libraries/Constants.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";

contract MiltonFacadeDataProviderTest is
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
    UsdtMockedToken internal _usdtMockedToken;
    UsdcMockedToken internal _usdcMockedToken;
    DaiMockedToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;
    address internal _miltonStorageAddress;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);
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
        _miltonStorageAddress = _getUserAddress(5);
    }

    function testShouldListConfigurationUsdtUsdcDai() public {
        //given
        _miltonSpreadModel.setCalculateSpreadPayFixed(1 * 10 ** 16); // 1%
        _miltonSpreadModel.setCalculateSpreadReceiveFixed(1 * 10 ** 16); // 1%
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (ProxyTester miltonFacadeDataProviderProxy, MiltonFacadeDataProvider miltonFacadeDataProvider) =
        getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        // when
        vm.prank(address(miltonFacadeDataProviderProxy));
        MiltonFacadeTypes.AssetConfiguration[] memory assetConfigurations = miltonFacadeDataProvider.getConfiguration();
        // then
        for (uint256 i = 0; i < assetConfigurations.length; ++i) {
            assertEq(10 * Constants.D18, assetConfigurations[i].minLeverage);
            assertEq(1000 * Constants.D18, assetConfigurations[i].maxLeverage);
            assertEq(3 * 10 ** 14, assetConfigurations[i].openingFeeRate); // 3 * N0__000_1_18DEC
            assertEq(10 * Constants.D18, assetConfigurations[i].iporPublicationFeeAmount);
            assertEq(20 * Constants.D18, assetConfigurations[i].liquidationDepositAmount);
            assertEq(1 * 10 ** 17, assetConfigurations[i].incomeFeeRate);
            assertEq(1 * 10 ** 16, assetConfigurations[i].spreadPayFixed);
            assertEq(1 * 10 ** 16, assetConfigurations[i].spreadReceiveFixed);
            assertEq(8 * 10 ** 17, assetConfigurations[i].maxLpUtilizationRate);
            assertEq(48 * 10 ** 16, assetConfigurations[i].maxLpUtilizationPerLegRate);
        }
    }

    function testShouldListCorrectNumberItemsUsdtUsdcDai() public {
        //given
        _miltonSpreadModel.setCalculateSpreadPayFixed(6 * 10 ** 16); // 6%
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        // when
        vm.prank(_userTwo);
        mockCase0Miltons.mockCase0MiltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            9 * 10 ** 17, // acceptableFixedInterestRate, 9 * N0__1_18DEC
            10 * Constants.D18 // leverage LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        mockCase0Miltons.mockCase0MiltonUsdc.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            9 * 10 ** 17, // acceptableFixedInterestRate, 9 * N0__1_18DEC
            10 * Constants.D18 // leverage LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        mockCase0Miltons.mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * Constants.D18, // totalAmount, TC_TOTAL_AMOUNT_10_000_18DEC
            9 * 10 ** 17, // acceptableFixedInterestRate, 9 * N0__1_18DEC
            10 * Constants.D18 // leverage LEVERAGE_18DEC
        );
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 50);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 50);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 50);
        // then
        assertEq(totalCountUsdt, 1);
        assertEq(totalCountUsdc, 1);
        assertEq(totalCountDai, 1);
        assertEq(swapsUsdt.length, 1);
        assertEq(swapsUsdc.length, 1);
        assertEq(swapsDai.length, 1);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(3, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(3, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldFailWhenPageSizeIsZero() public {
        //given
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 0, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 0);
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 0);
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 0);
        // then
        assertEq(totalCountUsdt, 0);
        assertEq(totalCountUsdc, 0);
        assertEq(totalCountDai, 0);
        assertEq(swapsUsdt.length, 0);
        assertEq(swapsUsdc.length, 0);
        assertEq(swapsDai.length, 0);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(0, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(0, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldFailWhenPageSizeIsGreaterThanFifty() public {
        //given
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 0, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 51);
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 51);
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 51);
        // then
        assertEq(totalCountUsdt, 0);
        assertEq(totalCountUsdc, 0);
        assertEq(totalCountDai, 0);
        assertEq(swapsUsdt.length, 0);
        assertEq(swapsUsdc.length, 0);
        assertEq(swapsDai.length, 0);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(0, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(0, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveEmptyListOfSwaps() public {
        //given
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 0, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 10);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 10);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 10);
        // then
        assertEq(totalCountUsdt, 0);
        assertEq(totalCountUsdc, 0);
        assertEq(totalCountDai, 0);
        assertEq(swapsUsdt.length, 0);
        assertEq(swapsUsdc.length, 0);
        assertEq(swapsDai.length, 0);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(0, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(0, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwap() public {
        //given
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 0, 10000 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 0, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 10, 10);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 10, 10);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 10, 10);
        // then
        assertEq(totalCountUsdt, 0);
        assertEq(totalCountUsdc, 0);
        assertEq(totalCountDai, 0);
        assertEq(swapsUsdt.length, 0);
        assertEq(swapsUsdc.length, 0);
        assertEq(swapsDai.length, 0);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(0, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(0, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveLimitedSwapArray() public {
        //given
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000047708334227);
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(50000 * Constants.D18, block.timestamp); // USD_50_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 11, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 11, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 11, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 10);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 10);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 10);
        // then
        assertEq(totalCountUsdt, 11);
        assertEq(totalCountUsdc, 11);
        assertEq(totalCountDai, 11);
        assertEq(swapsUsdt.length, 10);
        assertEq(swapsUsdc.length, 10);
        assertEq(swapsDai.length, 10);
        assertEq(33, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(30, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveLimitedSwapArrayWithOffset() public {
        //given
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(50000 * Constants.D18, block.timestamp); // USD_50_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 22, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 22, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 22, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 10, 10);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 10, 10);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 10, 10);
        // then
        assertEq(totalCountUsdt, 22);
        assertEq(totalCountUsdc, 22);
        assertEq(totalCountDai, 22);
        assertEq(swapsUsdt.length, 10);
        assertEq(swapsUsdc.length, 10);
        assertEq(swapsDai.length, 10);
        assertEq(66, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(30, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveRestOfSwapsOnly() public {
        //given
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            _admin,
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsdt(
            users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsdc(
            users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdt,
            miltonStorages.miltonStorageUsdtProxy,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageUsdc,
            miltonStorages.miltonStorageUsdcProxy,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareMiltonStorage(
            miltonStorages.miltonStorageDai,
            miltonStorages.miltonStorageDaiProxy,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMockCase0MiltonUsdt(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Miltons.mockCase0MiltonUsdtProxy),
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMockCase0MiltonUsdc(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Miltons.mockCase0MiltonUsdcProxy),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMockCase0MiltonDai(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Miltons.mockCase0MiltonDaiProxy),
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareMockCase0JosephUsdt(
            mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy)
        );
        prepareMockCase0JosephUsdc(
            mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy)
        );
        prepareMockCase0JosephDai(
            mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy)
        );
        prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
        (, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(
            _admin,
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 5 * 10 ** 16, block.timestamp); // PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(50000 * 10 ** 6, block.timestamp); // USD_50_000_6DEC
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(50000 * Constants.D18, block.timestamp); // USD_50_000_18DEC
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdt, 22, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(_userTwo, mockCase0Miltons.mockCase0MiltonUsdc, 22, 100 * 10 ** 6, 10 * Constants.D18);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0Miltons.mockCase0MiltonDai, 22, 100 * Constants.D18, 10 * Constants.D18
        );
        // when
        vm.prank(_userTwo);
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 20, 10);
        vm.prank(_userTwo);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 20, 10);
        vm.prank(_userTwo);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 20, 10);
        // then
        assertEq(totalCountUsdt, 22);
        assertEq(totalCountUsdc, 22);
        assertEq(totalCountDai, 22);
        assertEq(swapsUsdt.length, 2);
        assertEq(swapsUsdc.length, 2);
        assertEq(swapsDai.length, 2);
        assertEq(66, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(6, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }
}
