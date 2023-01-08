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
import  {SwapUtils} from "../utils/SwapUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldClosePositionTest is Test, TestCommons, MiltonUtils, MiltonStorageUtils, JosephUtils, IporOracleUtils, DataUtils, SwapUtils, StanleyUtils {
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

    function setUp() public {
		_miltonSpreadModel = prepareMockSpreadModel(
			6*10**16, // 6%
			4*10**16, // 4%
			0,
			0
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

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(161*10**16); // 161%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 161*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 9967009897030890732780; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(161*10**16); // 161%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 161*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 9967009897030890732780; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}


	function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(400*10**16); // 400%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 160*10**16); 
		MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 400*10**16, 10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 3*10**16, block.timestamp); // PERCENTAGE_3_18DEC
		int256 openerUserLost = 2990103 + 10*10**6 + 20*10**6 + 9967009897; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs 
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageUsdtProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		vm.prank(address(miltonStorageUsdtProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoffWad
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), 28000*10**6 + 2990103 + 10*10**6 + 9967009897); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
		assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), 10000000*10**6 + 20*10**6 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
		assertEq(28000*10**6 + 10000000*10**6, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))  + _usdtMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity6DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(400*10**16); // 400%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 160*10**16); 
		MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 400*10**16, 10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 3*10**16, block.timestamp); // PERCENTAGE_3_18DEC
		int256 openerUserLost = 2990103 + 10*10**6 + 20*10**6 + 9967009897; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs 
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageUsdtProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		vm.prank(address(miltonStorageUsdtProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoffWad
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), 28000*10**6 + 2990103 + 10*10**6 + 9967009897); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
		assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), 10*10**6*10**6 + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_usdtMockedToken.balanceOf(_userThree)), 10*10**6*10**6 + 20*10**6 - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
		assertEq(28000*10**6 + 10000000*10**6 + 10000000*10**6, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))  + _usdtMockedToken.balanceOf(_userTwo) + _usdtMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(121*10**16); // 121%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 121*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 7918994164764269383465; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -7918994164764269383465); // expectedPayoff
		assertEq(actualIncomeFeeValue, 791899416476426938347); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 7918994164764269383465); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 7918994164764269383465 - 791899416476426938347); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 791899416476426938347);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionUSDTWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(10*10**16); // 10%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 120*10**16); 
		MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 10*10**16, 10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990103 + 10*10**6 + 20*10**6 + 341335955; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC + expectedPayoffAbs 
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageUsdtProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		vm.prank(address(miltonStorageUsdtProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -341335955377770264707); // expectedPayoffWad
		assertEq(actualIncomeFeeValue, 34133595537777026471); // expectedIncomeFeeValue
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), 28000*10**6 + 2990103 + 10*10**6 + 341335955); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC + expectedPayoffAbs
		assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), 10000000*10**6 + 20*10**6 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 341335955377770264707 - 34133595537777026471); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 34133595537777026471); // expectedIncomeFeeValueWad
		assertEq(28000*10**6 + 10000000*10**6, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))  + _usdtMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(10*10**16); // 10%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 161*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 682671910755540429745; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 4320000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -682671910755540429745); // expectedPayoff
		assertEq(actualIncomeFeeValue, 68267191075554042975); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 682671910755540429745); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 682671910755540429745 - 68267191075554042975); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 68267191075554042975);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(10*10**16); // 10%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 161*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 682671910755540429745; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 4320000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -682671910755540429745); // expectedPayoff
		assertEq(actualIncomeFeeValue, 68267191075554042975); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 682671910755540429745); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 682671910755540429745 - 68267191075554042975); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 68267191075554042975);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}


	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 - 9967009897030890732780 + 2990102969109267220); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWadAbs + TC_OPENING_FEE_18DEC
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 5*10**16); 
		MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 10*10**16, 10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990103 + 10*10**6 + 20*10**6 - 9967009897 + 996700990; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageUsdtProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		vm.prank(address(miltonStorageUsdtProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoffWad
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValueWad
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), 28000*10**6 + 2990103 + 10*10**6 - 9967009897 + 996700990); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), 10000000*10**6 + 20*10**6 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEC - expectedPayoffWadAbs 
		assertEq(balance.treasury, 996700989703089073278); // expectedIncomeFeeValueWad
		assertEq(28000*10**6 + 10000000*10**6, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))  + _usdtMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(6*10**16); // 6%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 120*10**16, block.timestamp); // PERCENTAGE_120_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 7782459782613161235257 + 778245978261316123526; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 7782459782613161235257); // expectedPayoff
		assertEq(actualIncomeFeeValue, 778245978261316123526); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 7782459782613161235257 + 778245978261316123526); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 7782459782613161235257); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWadAbs + TC_OPENING_FEE_18DEC
		assertEq(balance.treasury, 778245978261316123526);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionUSDTWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity6DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(3*10**16); // 3%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_usdtMockedToken), 5*10**16); 
		MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
		(ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
		(ProxyTester mockCase0MiltonUsdtProxy, MockCase0MiltonUsdt mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(_admin, address(_usdtMockedToken), address(iporOracle), address(miltonStorageUsdt), address(_miltonSpreadModel), address(stanleyUsdt));
		(ProxyTester mockCase0JosephUsdtProxy, MockCase0JosephUsdt mockCase0JosephUsdt) = getMockCase0JosephUsdt(_admin, address(_usdtMockedToken), address(_ipTokenUsdt), address(mockCase0MiltonUsdt), address(miltonStorageUsdt), address(stanleyUsdt));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersUsdt(users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
		prepareMockCase0MiltonUsdt(mockCase0MiltonUsdt, address(mockCase0MiltonUsdtProxy), address(mockCase0JosephUsdt), address(stanleyUsdt));
		prepareMockCase0JosephUsdt(mockCase0JosephUsdt, address(mockCase0JosephUsdtProxy));
		prepareIpTokenUsdt(_ipTokenUsdt, address(mockCase0JosephUsdt));
		vm.prank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(28000*10**6, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*10**6, 10*10**16, 10*Constants.D18, mockCase0MiltonUsdt);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), 6*10**16, block.timestamp); // PERCENTAGE_3_18DEC
		int256 openerUserLost = 2990103 + 10*10**6 + 20*10**6 - 204801573 + 20480157; // TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonUsdt.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonUsdt.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageUsdtProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
		vm.prank(address(miltonStorageUsdtProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageUsdt.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonUsdt);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 204801573226662097384); // expectedPayoffWad
		assertEq(actualIncomeFeeValue, 20480157322666209738); // expectedIncomeFeeValueWad
		assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), 28000*10**6 + 2990103 + 10*10**6 - 204801573 + 20480157); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_6DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), 10000000*10**6 + 20*10**6 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 204801573226662097384); // TC_LP_BALANCE_BEFORE_CLOSE_6DEC + TC_OPENING_FEE_18DEX - expectedPayoffWadAbs 
		assertEq(balance.treasury, 20480157322666209738); // expectedIncomeFeeValueWad
		assertEq(28000*10**6 + 10000000*10**6, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))  + _usdtMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}


	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(6*10**16); // 6%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 50*10**16, block.timestamp); // PERCENTAGE_50_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 6007512814648756073133 + 600751281464875607313; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 4320000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 6007512814648756073133); // expectedPayoff
		assertEq(actualIncomeFeeValue, 600751281464875607313); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 6007512814648756073133 + 600751281464875607313); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 6007512814648756073133); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 600751281464875607313);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedLessThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(6*10**16); // 6%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 50*10**16, block.timestamp); // PERCENTAGE_50_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 6007512814648756073133 + 600751281464875607313; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 4320000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 6007512814648756073133); // expectedPayoff
		assertEq(actualIncomeFeeValue, 600751281464875607313); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 6007512814648756073133 + 600751281464875607313); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 6007512814648756073133); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 600751281464875607313);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedMoreThanCollateralAfterBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonLostAndUserEarnedBetween99And100PercentOfCollateralAfterBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(6*10**16); // 6%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 151*10**16, block.timestamp); // PERCENTAGE_151_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9898742705955336652531 + 989874270595533665253; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9898742705955336652531); // expectedPayoff
		assertEq(actualIncomeFeeValue, 989874270595533665253); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9898742705955336652531 + 989874270595533665253); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9898742705955336652531); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 989874270595533665253);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostBetween99And100PercentOfCollateralBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(151*10**16); // 151%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 150*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 151*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 6*10**16, block.timestamp); // PERCENTAGE_6_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 9898742705955336727624; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs 
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9898742705955336727624); // expectedPayoff
		assertEq(actualIncomeFeeValue, 989874270595533672762); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 9898742705955336727624); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9898742705955336727624 - 989874270595533672762); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 989874270595533672762);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(121*10**16); // 121%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 121*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 8803281846496279452160 ; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2401200, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2401200);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2401200, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -8803281846496279452160); // expectedPayoff
		assertEq(actualIncomeFeeValue, 880328184649627945216); // expectedIncomeFeeValueWad
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 8803281846496279452160); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 8803281846496279452160 - 880328184649627945216); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 880328184649627945216);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenPayFixedMiltonEarnedAndUserLostMoreThanCollateralAfterMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(161*10**16); // 161%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 161*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 9967009897030890732780; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 4320000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedLessThanCollateralFiveHoursBeforeMaturity18DecimalsAndDifferentUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(10*10**16); // 10%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 10*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 379451803728287931809 + 37945180372828793181; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 2401200, 1);
		vm.prank(_userThree); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2401200);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2401200, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 379451803728287931809); // expectedPayoff
		assertEq(actualIncomeFeeValue, 37945180372828793181); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 379451803728287931809 + 37945180372828793181); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 379451803728287931809); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 37945180372828793181);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(159*10**16); // 159%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 159*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE - expectedPayoffWadAbs 
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor6Percent() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(1*10**16); // 1%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 6*10**16, block.timestamp); // PERCENTAGE_6_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 341335955377770189613; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -341335955377770189613); // expectedPayoff
		assertEq(actualIncomeFeeValue, 34133595537777018961); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 341335955377770189613); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 341335955377770189613 - 34133595537777018961); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 34133595537777018961);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostMoreThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor160Percent() public {
		_miltonSpreadModel.setCalculateQuotePayFixed(4*10**16); // 4%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 4*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_160_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 9967009897030890732780; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 9967009897030890732780 - 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity18DecimalsAndSameUserOpensAndClosesAndIpor120Percent() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(4*10**16); // 4%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 4*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 120*10**16, block.timestamp); // PERCENTAGE_120_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT + 7918994164764269327486; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC + expectedPayoffAbs
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 2160000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, -7918994164764269327486); // expectedPayoff
		assertEq(actualIncomeFeeValue, 791899416476426932749); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 + 7918994164764269327486); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + expectedPayoffAbs
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 + 7918994164764269327486 - 791899416476426932749); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE + expectedPayoffWadAbs - expectedIncomeFeeValueWad
		assertEq(balance.treasury, 791899416476426932749);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldClosePositionDAIWhenReceiveFixedMiltonLostAndUserEarnedMoreThanCollateralAfterMaturity18DecimalsAndSameUserOpensAndCloses() public {
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(159*10**16); // 159%
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 160*10**16); 
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 159*10**16, 10*Constants.D18, mockCase0MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 996700989703089073278; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase0MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userTwo); // closerUser
		mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 4320000);
		vm.prank(_userTwo); // closerUser
		uint256 actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase0MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 996700989703089073278); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 996700989703089073278); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*Constants.D18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 + 2990102969109267220 - 9967009897030890732780); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC - expectedPayoffWadAbs
		assertEq(balance.treasury, 996700989703089073278);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase0MiltonDai))  + _daiMockedToken.balanceOf(_userTwo)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}


}