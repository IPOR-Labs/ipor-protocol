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
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
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
		ItfMiltons memory itfMiltons = getItfMiltons(_admin, address(iporOracle), address(_miltonSpreadModel), address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken), miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory itfMiltonAddresses = getItfMiltonAddresses(address(itfMiltons.itfMiltonUsdt), address(itfMiltons.itfMiltonUsdc), address(itfMiltons.itfMiltonDai));
		ItfJosephs memory itfJosephs = getItfJosephs(_admin, tokenAddresses, ipTokenAddresses, itfMiltonAddresses, miltonStorageAddresses, mockCase1StanleyAddresses);
		address[] memory itfJosephAddresses = getItfJosephAddresses(address(itfJosephs.itfJosephUsdt), address(itfJosephs.itfJosephUsdc), address(itfJosephs.itfJosephDai));
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(itfJosephs.itfJosephUsdt), address(itfMiltons.itfMiltonUsdt));
		prepareApproveForUsersUsdc(users, _usdcMockedToken, address(itfJosephs.itfJosephUsdc), address(itfMiltons.itfMiltonUsdc));
		prepareApproveForUsersDai(users, _daiMockedToken, address(itfJosephs.itfJosephDai), address(itfMiltons.itfMiltonDai));
		prepareMiltonStorage(miltonStorages.miltonStorageUsdt, miltonStorages.miltonStorageUsdtProxy, address(itfJosephs.itfJosephUsdt), address(itfMiltons.itfMiltonUsdt));
		prepareMiltonStorage(miltonStorages.miltonStorageUsdc, miltonStorages.miltonStorageUsdcProxy, address(itfJosephs.itfJosephUsdc), address(itfMiltons.itfMiltonUsdc));
		prepareMiltonStorage(miltonStorages.miltonStorageDai, miltonStorages.miltonStorageDaiProxy, address(itfJosephs.itfJosephDai), address(itfMiltons.itfMiltonDai));
		prepareItfMiltonUsdt(itfMiltons.itfMiltonUsdt, address(itfMiltons.itfMiltonUsdtProxy), address(itfJosephs.itfJosephUsdt), mockCase1StanleyAddresses[0]);
		prepareItfMiltonUsdc(itfMiltons.itfMiltonUsdc, address(itfMiltons.itfMiltonUsdcProxy), address(itfJosephs.itfJosephUsdc), mockCase1StanleyAddresses[1]);
		prepareItfMiltonDai(itfMiltons.itfMiltonDai, address(itfMiltons.itfMiltonDaiProxy), address(itfJosephs.itfJosephDai), mockCase1StanleyAddresses[2]);
		prepareItfJosephUsdt(itfJosephs.itfJosephUsdt, address(itfJosephs.itfJosephUsdtProxy));
		prepareItfJosephUsdc(itfJosephs.itfJosephUsdc, address(itfJosephs.itfJosephUsdcProxy));
		prepareItfJosephDai(itfJosephs.itfJosephDai, address(itfJosephs.itfJosephDaiProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, itfJosephAddresses[0]);
		prepareIpTokenUsdc(_ipTokenUsdc, itfJosephAddresses[1]);
		prepareIpTokenDai(_ipTokenDai, itfJosephAddresses[2]);
		(ProxyTester miltonFacadeDataProviderProxy, MiltonFacadeDataProvider miltonFacadeDataProvider) = getMiltonFacadeDataProvider(_admin, address(iporOracle), tokenAddresses, itfMiltonAddresses, miltonStorageAddresses, itfJosephAddresses);	
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdcMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		vm.prank(_liquidityProvider);
		itfJosephs.itfJosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp) ; // USD_28_000_6DEC
		vm.prank(_liquidityProvider);
		itfJosephs.itfJosephUsdc.itfProvideLiquidity(28000*10**6, block.timestamp) ; // USD_28_000_6DEC
		vm.prank(_liquidityProvider);
		itfJosephs.itfJosephDai.itfProvideLiquidity(28000*10**18, block.timestamp) ; // USD_28_000_6DEC
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