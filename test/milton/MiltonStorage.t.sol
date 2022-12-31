// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import  {DataUtils} from "../utils/DataUtils.sol";
import  {MiltonUtils} from "../utils/MiltonUtils.sol";
import  {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import  {JosephUtils} from "../utils/JosephUtils.sol";
import  {StanleyUtils} from "../utils/StanleyUtils.sol";
import  {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import  {SwapUtils} from "../utils/SwapUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract MiltonStorageTest is Test, TestCommons, MiltonUtils, MiltonStorageUtils, JosephUtils, IporOracleUtils, DataUtils, SwapUtils, StanleyUtils {
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
		_miltonSpreadModel = prepareMockSpreadModel(
			6*10**16, // 6%
			4*10**16, // 4%
			0, // 0%
			0 // 0%
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
    }

	function testShouldTransferOwnershipSimpleCase1() public {
		// given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		miltonStorageDai.confirmTransferOwnership();
		// then
		vm.prank(address(_userOne));
		address newOwner = miltonStorageDai.owner();
		assertEq(_userTwo, newOwner);
	}

	function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
		// given
		(, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(_userThree);
		miltonStorageDai.transferOwnership(_userTwo);
	}

	function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
		// given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when 
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		// then
		vm.expectRevert("IPOR_007");
		vm.prank(_userThree);
		miltonStorageDai.confirmTransferOwnership();
	}

	function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
		// given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when 
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		miltonStorageDai.confirmTransferOwnership();
		vm.expectRevert("IPOR_007");
		vm.prank(_userThree);
		miltonStorageDai.confirmTransferOwnership();
	}

	function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
		// given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when 
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		miltonStorageDai.confirmTransferOwnership();
		vm.expectRevert("Ownable: caller is not the owner");
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userThree);
	}

	function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
		// given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		// when 
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.transferOwnership(_userTwo);
		vm.prank(_userOne);
		// then
		address actualOwner = miltonStorageDai.owner();
		assertEq(actualOwner, address(miltonStorageDaiProxy));
	}

	function testShouldUpdateMiltonStorageWhenOpenPositionAndCallerHasRightsToUpdate() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0); 
		MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(_miltonStorageAddress);
		AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
		vm.prank(address(mockCase0MiltonDaiProxy));
		uint256 iporPublicationFee = mockCase0MiltonDai.getIporPublicationFee();
		// when
		vm.prank(_miltonStorageAddress);
		uint256 swapId = miltonStorageDai.updateStorageWhenOpenSwapPayFixed(newSwap, iporPublicationFee);
		// then
		assertEq(swapId, 1);
	}

	function testShouldNotUpdateMiltonStorageWhenOpenPositionAndCallerDoesNotHaveRightsToUpdate() public {
		// given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0); 
		MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(_miltonStorageAddress);
		AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
		vm.prank(address(mockCase0MiltonDaiProxy));
		uint256 iporPublicationFee = mockCase0MiltonDai.getIporPublicationFee();
		// when
		vm.expectRevert("IPOR_008");
		vm.prank(_userThree);
		miltonStorageDai.updateStorageWhenOpenSwapPayFixed(newSwap, iporPublicationFee);
	}

	function testShouldNotAddLiquidityWhenAssetAmountIsZero() public {
		//given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setJoseph(_liquidityProvider);
		// when
		vm.expectRevert("IPOR_328");
		vm.prank(_liquidityProvider);
		miltonStorageDai.addLiquidity(_liquidityProvider, 0, 10000000*Constants.D18, 10000000*Constants.D18);
	}

	function testShouldNotUpdateStorageWhenTransferredAmountToTreasuryIsGreaterThanBalance()public {
		//given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setJoseph(_liquidityProvider);
		// when
		vm.expectRevert("IPOR_330");
		vm.prank(_liquidityProvider);
		miltonStorageDai.updateStorageWhenTransferToTreasury(Constants.D18*Constants.D18);
	}

	function testShouldNotUpdateStorageWhenVaultBalanceIsLowerThanDepositAmount()public {
		//given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(_miltonStorageAddress);
		// when
		vm.expectRevert("IPOR_329");
		vm.prank(_miltonStorageAddress);
		miltonStorageDai.updateStorageWhenDepositToStanley(Constants.D18, 0);
	}

	function testShouldNotUpdateStorageWhenTransferredAmountToCharliesGreaterThanBalacer()public {
		//given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setJoseph(_liquidityProvider);
		// when
		vm.expectRevert("IPOR_326");
		vm.prank(_liquidityProvider);
		miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(Constants.D18*Constants.D18);
	}

	function testShouldNotUpdateStorageWhenSendZero()public {
		//given
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setJoseph(_liquidityProvider);
		// when
		vm.expectRevert("IPOR_006");
		vm.prank(_liquidityProvider);
		miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(0);
	}

	function testShouldUpdateMiltonStorageWhenClosePositionAndCallerHasRightsToUpdateDAI18Decimals() public {
		//given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0); 
		MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(stanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(_miltonStorageAddress);
		vm.prank(address(mockCase0MiltonDai));
		IporTypes.IporSwapMemory memory derivativeItem = miltonStorageDai.getSwapPayFixed(1);
		// when
		vm.prank(_miltonStorageAddress);
		miltonStorageDai.updateStorageWhenCloseSwapPayFixed(address(_userTwo), derivativeItem, 10*Constants.D18_INT, 1*Constants.D18, block.timestamp + 2160000, 95*10**16, 21600);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(address(mockCase0MiltonDai));
	}

	function testShouldUpdateMiltonStorageWhenClosePositionAndCallerHasRightsToUpdateUSDT6Decimals() public {
		//given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0); 
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenDai(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // USD_28_000_6DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 9*10**17,10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(address(miltonStorageUsdtProxy));
		miltonStorageUsdt.setMilton(_miltonStorageAddress);
		vm.prank(address(mockCase0MiltonUsdt));
		IporTypes.IporSwapMemory memory derivativeItem = miltonStorageUsdt.getSwapPayFixed(1);
		// when
		vm.prank(_miltonStorageAddress);
		miltonStorageUsdt.updateStorageWhenCloseSwapPayFixed(address(_userTwo), derivativeItem, 10*Constants.D18_INT, 1*Constants.D18, block.timestamp + 2160000, 95*10**16, 21600);
		vm.prank(address(miltonStorageUsdtProxy));
		miltonStorageUsdt.setMilton(address(mockCase0MiltonUsdt));
	}

	function testShouldNotUpdateMiltonStorageWhenClosePositionAndCallerDoesNotHaveRightsToUpdate() public {
		//given
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0); 
		MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase0MiltonDai), address(miltonStorageDai), address(stanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai));
		prepareMockCase0MiltonDai(mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // USD_28_000_18DEC
        openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 9*10**17,10*Constants.D18, mockCase0MiltonDai);
		vm.prank(address(miltonStorageDaiProxy));
		miltonStorageDai.setMilton(_miltonStorageAddress);
		vm.prank(address(mockCase0MiltonDai));
		IporTypes.IporSwapMemory memory derivativeItem = miltonStorageDai.getSwapPayFixed(1);
		// when
		vm.expectRevert("IPOR_008");
		vm.prank(_userThree);
		miltonStorageDai.updateStorageWhenCloseSwapPayFixed(address(_userTwo), derivativeItem, 10*Constants.D18_INT, 1*Constants.D18, block.timestamp + 2160000, 95*10**16, 21600);
	}

	function testGetSwapsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.expectRevert("IPOR_009");
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 0);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 11, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 11);
		assertEq(swaps.length, 10);
	}

	function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(swaps.length, 10);
	}

	function testGetSwapsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(swaps.length, 2);
	}

	function testGetSwapsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 20, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 20);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.expectRevert("IPOR_009");
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 0, 0);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(swaps.length, 0);
	}

	function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 11, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 11);
		assertEq(swaps.length, 1);
	}	

	function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(swaps.length, 10);
	}

	function testGetSwapsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(swaps.length, 2);
	}

	function testGetSwapIdsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.expectRevert("IPOR_009");
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 0, 0);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 11, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 11);
		assertEq(ids.length, 10);
	}

	function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(ids.length, 10);
	}

	function testGetSwapIdsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(ids.length, 2);
	}

	function testGetSwapIdsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 20, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 20);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.expectRevert("IPOR_009");
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 0, 0);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 11, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 11);
		assertEq(ids.length, 1);
	}	

	function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(ids.length, 10);
	}

	function testGetSwapIdsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 22, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 20, 10);
		// then
		assertEq(totalCount, 22);
		assertEq(ids.length, 2);
	}

	function testGetSwapIdsShouldFailWhenPageSizeIsEqualToZero() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.expectRevert("IPOR_009");
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 0);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 10, 10);
		// then
		assertEq(totalCount, 0);
		assertEq(ids.length, 0);
	}

	function testGetSwapIdsShouldReturnPayFixedSwapsWhenUserDoesNotHaveReceiveFixedSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 5, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 5);
		assertEq(ids.length, 5);
	}	

	function testGetSwapIdsShouldReturnReceiveFixedSwapsWhenUserDoesNotHavePayFixedSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 0, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 5, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 5);
		assertEq(ids.length, 5);
	}	

	function testGetSwapIdsShouldReturn6SwapsWhenUserHas3PayFixedSwapsAnd3ReceiveFixedSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 3, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 3, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 6);
		assertEq(ids.length, 6);
	}	

	function testGetSwapIdsShouldReturnLimited10SwapsWhenUserHas9PayFixedSwapsAnd12ReceiveFixedSwapsAndOffsetZeroAndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 9, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 12, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 0, 10);
		// then
		assertEq(totalCount, 21);
		assertEq(ids.length, 10);
	}	
	
	function testGetSwapIdsShouldReturnEmptyArrayWhenUserHasMoreSwapsThanPageSizeAndOffset80AndPageSize10() public {
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 0);
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne); 
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(50000*10**6, block.timestamp); // USD_50_000_6DEC
		iterateOpenSwapsPayFixed(_userTwo, mockCase0MiltonUsdt, 9, 100*10**6, 10 * Constants.D18);
		iterateOpenSwapsReceiveFixed(_userTwo, mockCase0MiltonUsdt, 12, 100*10**6, 10 * Constants.D18);
		// when
		vm.prank(address(miltonStorageUsdtProxy));
		(uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) = miltonStorageUsdt.getSwapIds(_userTwo, 80, 10);
		// then
		assertEq(totalCount, 21);
		assertEq(ids.length, 0);
	}	

}