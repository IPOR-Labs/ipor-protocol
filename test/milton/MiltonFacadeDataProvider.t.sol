// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import "../../contracts/interfaces/types/MiltonFacadeTypes.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/IMiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";

contract MiltonFacadeDataProviderTest is Test, TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    address internal _miltonStorageAddress;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
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
        _miltonStorageAddress = _getUserAddress(5);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldListConfigurationUsdtUsdcDai() public {
        //given
        _miltonSpreadModel.setCalculateSpreadPayFixed(1 * TestConstants.D16_INT); // 1%
        _miltonSpreadModel.setCalculateSpreadReceiveFixed(1 * TestConstants.D16_INT); // 1%
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // USD_28_000_18DEC
		vm.stopPrank();
        // when
        MiltonFacadeTypes.AssetConfiguration[] memory assetConfigurations = miltonFacadeDataProvider.getConfiguration();
        // then
        for (uint256 i = 0; i < assetConfigurations.length; ++i) {
            assertEq(TestConstants.LEVERAGE_18DEC, assetConfigurations[i].minLeverage);
            assertEq(TestConstants.LEVERAGE_1000_18DEC, assetConfigurations[i].maxLeverage);
            assertEq(3 * TestConstants.D14, assetConfigurations[i].openingFeeRate);
            assertEq(TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, assetConfigurations[i].iporPublicationFeeAmount);
            assertEq(TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, assetConfigurations[i].liquidationDepositAmount);
            assertEq(1 * TestConstants.D17, assetConfigurations[i].incomeFeeRate);
            assertEq(1 * TestConstants.D16_INT, assetConfigurations[i].spreadPayFixed);
            assertEq(1 * TestConstants.D16_INT, assetConfigurations[i].spreadReceiveFixed);
            assertEq(8 * TestConstants.D17, assetConfigurations[i].maxLpUtilizationRate);
            assertEq(48 * TestConstants.D16, assetConfigurations[i].maxLpUtilizationPerLegRate);
        }
    }

    function testShouldListCorrectNumberItemsUsdtUsdcDai() public {
        //given
        _miltonSpreadModel.setCalculateSpreadPayFixed(6 * TestConstants.D16_INT); // 6%
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        vm.stopPrank();
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // USD_28_000_18DEC
		vm.stopPrank();
        // when
        vm.startPrank(_userTwo);
        mockCase0Miltons.mockCase0MiltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, // totalAmount
            9 * TestConstants.D17, // acceptableFixedInterestRate
            TestConstants.LEVERAGE_18DEC // leverage
        );
        mockCase0Miltons.mockCase0MiltonUsdc.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, // totalAmount
            9 * TestConstants.D17, // acceptableFixedInterestRate
            TestConstants.LEVERAGE_18DEC // leverage
        );
        mockCase0Miltons.mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, // totalAmount
            9 * TestConstants.D17, // acceptableFixedInterestRate
            TestConstants.LEVERAGE_18DEC // leverage
        );
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), TestConstants.ZERO, 50);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), TestConstants.ZERO, 50);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), TestConstants.ZERO, 50);
		vm.stopPrank();
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
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // PERCENTAGE_5_18DEC
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // USD_28_000_18DEC
		vm.stopPrank();
        vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai,
            0,
            TestConstants.TC_TOTAL_AMOUNT_100_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 0);
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 0);
        vm.expectRevert(abi.encodePacked("IPOR_009"));
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 0);
		vm.stopPrank();
        // then
        assertEq(totalCountUsdt, TestConstants.ZERO);
        assertEq(totalCountUsdc, TestConstants.ZERO);
        assertEq(totalCountDai, TestConstants.ZERO);
        assertEq(swapsUsdt.length, TestConstants.ZERO);
        assertEq(swapsUsdc.length, TestConstants.ZERO);
        assertEq(swapsDai.length, TestConstants.ZERO);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(0, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(0, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldFailWhenPageSizeIsGreaterThanFifty() public {
        //given
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		vm.stopPrank();
		vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
			mockCase0Miltons.mockCase0MiltonDai,
			0,
			TestConstants.USD_100_18DEC,
			TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 51);
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 51);
        vm.expectRevert(abi.encodePacked("IPOR_010"));
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 51);
        vm.stopPrank();
        // then
        assertEq(totalCountUsdt, TestConstants.ZERO);
        assertEq(totalCountUsdc, TestConstants.ZERO);
        assertEq(totalCountDai, TestConstants.ZERO);
        assertEq(swapsUsdt.length, TestConstants.ZERO);
        assertEq(swapsUsdc.length, TestConstants.ZERO);
        assertEq(swapsDai.length, TestConstants.ZERO);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(TestConstants.ZERO, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(TestConstants.ZERO, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveEmptyListOfSwaps() public {
        //given
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		vm.stopPrank();
		vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai, 0, TestConstants.USD_100_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 10);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 10);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 10);
		vm.stopPrank();
        // then
        assertEq(totalCountUsdt, TestConstants.ZERO);
        assertEq(totalCountUsdc, TestConstants.ZERO);
        assertEq(totalCountDai, TestConstants.ZERO);
        assertEq(swapsUsdt.length, TestConstants.ZERO);
        assertEq(swapsUsdc.length, TestConstants.ZERO);
        assertEq(swapsDai.length, TestConstants.ZERO);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(TestConstants.ZERO, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(TestConstants.ZERO, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwap() public {
        //given
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
		vm.stopPrank();
		vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc,
            0,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai, 0, TestConstants.USD_100_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 10, 10);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 10, 10);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 10, 10);
		vm.stopPrank();
        // then
        assertEq(totalCountUsdt, TestConstants.ZERO);
        assertEq(totalCountUsdc, TestConstants.ZERO);
        assertEq(totalCountDai, TestConstants.ZERO);
        assertEq(swapsUsdt.length, TestConstants.ZERO);
        assertEq(swapsUsdc.length, TestConstants.ZERO);
        assertEq(swapsDai.length, TestConstants.ZERO);
        assertEq(swapsUsdt.length, totalCountUsdt);
        assertEq(swapsUsdc.length, totalCountUsdc);
        assertEq(swapsDai.length, totalCountDai);
        assertEq(TestConstants.ZERO, totalCountUsdt + totalCountUsdc + totalCountDai);
        assertEq(TestConstants.ZERO, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldReceiveLimitedSwapArray() public {
        //given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000047708334227);
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
		vm.stopPrank();
		vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai, 11, TestConstants.USD_100_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 0, 10);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 0, 10);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 0, 10);
		vm.stopPrank();
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
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
		vm.stopPrank();
		vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai, 22, TestConstants.USD_100_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 10, 10);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 10, 10);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 10, 10);
		vm.stopPrank();
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
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle =
            getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), 5e16, 0);
        address[] memory mockCase1StanleyAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdcMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Miltons.mockCase0MiltonUsdc)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdc,
            address(mockCase0Josephs.mockCase0JosephUsdc),
            mockCase1StanleyAddresses[1]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdc);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenUsdc, mockCase0JosephAddresses[1]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        IMiltonFacadeDataProvider miltonFacadeDataProvider = getMiltonFacadeDataProvider(
            address(iporOracle),
            tokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase0JosephAddresses
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdcMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
		vm.stopPrank();
        vm.startPrank(_userTwo);
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonUsdc, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsPayFixed(
            mockCase0Miltons.mockCase0MiltonDai, 22, TestConstants.USD_100_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCountUsdt, MiltonFacadeTypes.IporSwap[] memory swapsUsdt) =
            miltonFacadeDataProvider.getMySwaps(address(_usdtMockedToken), 20, 10);
        (uint256 totalCountUsdc, MiltonFacadeTypes.IporSwap[] memory swapsUsdc) =
            miltonFacadeDataProvider.getMySwaps(address(_usdcMockedToken), 20, 10);
        (uint256 totalCountDai, MiltonFacadeTypes.IporSwap[] memory swapsDai) =
            miltonFacadeDataProvider.getMySwaps(address(_daiMockedToken), 20, 10);
		vm.stopPrank();
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
