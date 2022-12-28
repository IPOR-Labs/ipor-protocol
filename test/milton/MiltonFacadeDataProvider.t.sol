// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import "../../contracts/interfaces/types/MiltonFacadeTypes.sol";
import  {DataUtils} from "../utils/DataUtils.sol";
import  {MiltonUtils} from "../utils/MiltonUtils.sol";
import  {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import  {JosephUtils} from "../utils/JosephUtils.sol";
import  {StanleyUtils} from "../utils/StanleyUtils.sol";
import  {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
// import "../../contracts/amm/MiltonStorage.sol";
// import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
// import "../../contracts/interfaces/types/MiltonTypes.sol";
// import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonFacadeDataProviderTest is Test, TestCommons, MiltonUtils, MiltonStorageUtils, JosephUtils, IporOracleUtils, DataUtils, StanleyUtils {
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
		_miltonSpreadModel.setCalculateSpreadPayFixed(1*10**16); // 1%
		_miltonSpreadModel.setCalculateSpreadReceiveFixed(1*10**16); // 1%
		address[] memory tokenAddresses = getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
		address[] memory ipTokenAddresses = getIpTokenAddresses(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
		address[] memory users = getUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		ItfIporOracle iporOracle = getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5*10**16, 0); 
		address[] memory mockCase1StanleyAddresses = getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
		MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
		address[] memory miltonStorageAddresses = getMiltonStorageAddresses(address(miltonStorages.miltonStorageUsdt), address(miltonStorages.miltonStorageUsdc), address(miltonStorages.miltonStorageDai));
		MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(_admin, address(iporOracle), address(_miltonSpreadModel), address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken), miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory mockCase0MiltonAddresses = getMockCase0MiltonAddresses(address(mockCase0Miltons.mockCase0MiltonUsdt), address(mockCase0Miltons.mockCase0MiltonUsdc), address(mockCase0Miltons.mockCase0MiltonDai));
		MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(_admin, tokenAddresses, ipTokenAddresses, mockCase0MiltonAddresses, miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory mockCase0JosephAddresses = getMockCase0JosephAddresses(address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Josephs.mockCase0JosephUsdc), address(mockCase0Josephs.mockCase0JosephDai));
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Miltons.mockCase0MiltonUsdt));
		prepareApproveForUsersUsdc(users, _usdcMockedToken, address(mockCase0Josephs.mockCase0JosephUsdc), address(mockCase0Miltons.mockCase0MiltonUsdc));
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0Josephs.mockCase0JosephDai), address(mockCase0Miltons.mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorages.miltonStorageUsdt, miltonStorages.miltonStorageUsdtProxy, address(mockCase0Josephs.mockCase0JosephUsdt), address(mockCase0Miltons.mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorages.miltonStorageUsdc, miltonStorages.miltonStorageUsdcProxy, address(mockCase0Josephs.mockCase0JosephUsdc), address(mockCase0Miltons.mockCase0MiltonUsdc));
		prepareMiltonStorage(miltonStorages.miltonStorageDai, miltonStorages.miltonStorageDaiProxy, address(mockCase0Josephs.mockCase0JosephDai), address(mockCase0Miltons.mockCase0MiltonDai));
		prepareMockCase0MiltonUsdt(mockCase0Miltons.mockCase0MiltonUsdt, address(mockCase0Miltons.mockCase0MiltonUsdtProxy), address(mockCase0Josephs.mockCase0JosephUsdt), mockCase1StanleyAddresses[0]);
		prepareMockCase0MiltonUsdc(mockCase0Miltons.mockCase0MiltonUsdc, address(mockCase0Miltons.mockCase0MiltonUsdcProxy), address(mockCase0Josephs.mockCase0JosephUsdc), mockCase1StanleyAddresses[1]);
		prepareMockCase0MiltonDai(mockCase0Miltons.mockCase0MiltonDai, address(mockCase0Miltons.mockCase0MiltonDaiProxy), address(mockCase0Josephs.mockCase0JosephDai), mockCase1StanleyAddresses[2]);
		prepareMockCase0JosephUsdt(mockCase0Josephs.mockCase0JosephUsdt, address(mockCase0Josephs.mockCase0JosephUsdtProxy));
		prepareMockCase0JosephUsdc(mockCase0Josephs.mockCase0JosephUsdc, address(mockCase0Josephs.mockCase0JosephUsdcProxy));
		prepareMockCase0JosephDai(mockCase0Josephs.mockCase0JosephDai, address(mockCase0Josephs.mockCase0JosephDaiProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, mockCase0JosephAddresses[0]);
		prepareIpTokenUsdc(_ipTokenUsdc, mockCase0JosephAddresses[1]);
		prepareIpTokenDai(_ipTokenDai, mockCase0JosephAddresses[2]);
		(ProxyTester miltonFacadeDataProviderProxy, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(_admin, address(iporOracle), tokenAddresses, mockCase0MiltonAddresses, miltonStorageAddresses, mockCase0JosephAddresses);	
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_liquidityProvider);
		mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp) ; // USD_28_000_6DEC
		vm.prank(_liquidityProvider);
		mockCase0Josephs.mockCase0JosephUsdc.itfProvideLiquidity(28000*10**6, block.timestamp) ; // USD_28_000_6DEC
		vm.prank(_liquidityProvider);
		mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(28000*10**18, block.timestamp) ; // USD_28_000_6DEC
		// when
		vm.prank(address(miltonFacadeDataProviderProxy));
		MiltonFacadeTypes.AssetConfiguration[] memory assetConfigurations = miltonFacadeDataProvider.getConfiguration();
		// then
		for(uint256 i = 0; i < assetConfigurations.length; ++i){
			assertEq(10*Constants.D18, assetConfigurations[i].minLeverage);
			assertEq(1000*Constants.D18, assetConfigurations[i].maxLeverage);
			assertEq(3*10**14, assetConfigurations[i].openingFeeRate); // 3 * N0__000_1_18DEC 
			assertEq(10*Constants.D18, assetConfigurations[i].iporPublicationFeeAmount);
			assertEq(20*Constants.D18, assetConfigurations[i].liquidationDepositAmount);
			assertEq(1*10**17, assetConfigurations[i].incomeFeeRate);
			assertEq(1*10**16, assetConfigurations[i].spreadPayFixed);
			assertEq(1*10**16, assetConfigurations[i].spreadReceiveFixed);
			assertEq(8*10**17, assetConfigurations[i].maxLpUtilizationRate);
			assertEq(48*10**16, assetConfigurations[i].maxLpUtilizationPerLegRate);
		}
	}
}