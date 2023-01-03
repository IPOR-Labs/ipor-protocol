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
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldCalculateTest is Test, TestCommons, MiltonUtils, MiltonStorageUtils, JosephUtils, IporOracleUtils, DataUtils, SwapUtils, StanleyUtils {
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
			4*10**16, // 4%
			2*10**16, // 2%
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

	function testShouldCalculateIncomeFeeFivePercentWhenReceiveFixedAndNotOwnerAndMiltonLosesAndUserEarnsAndDepositIsGreaterThanDifferenceBetweenLegs() public {
		// given
		_miltonSpreadModel.setCalculateQuoteReceiveFixed(1*10**17);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 120*10**16); 
		MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase2MiltonDaiProxy, MockCase2MiltonDai mockCase2MiltonDai) = getMockCase2MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase2MiltonDai), address(miltonStorageDai), address(stanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase2MiltonDai));
		prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase2MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapReceiveFixed(_userTwo, block.timestamp, 10000*Constants.D18, 1*10**17, 10*Constants.D18, mockCase2MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 5*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 682671910755540429746 + 34133595537777021487; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapReceiveFixedValue(block.timestamp + 4320000, 1);
		vm.prank(_userThree); // closerUser
		mockCase2MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + 4320000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsReceiveFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 4320000, mockCase2MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 682671910755540429746); // expectedPayoff
		assertEq(actualIncomeFeeValue, 34133595537777021487); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase2MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 682671910755540429746 + 34133595537777021487); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralReceiveFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*10**18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 - 682671910755540429746 + 2990102969109267220); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC
		assertEq(balance.treasury, 34133595537777021487);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase2MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}

	function testShouldCalculateIncomeFeeFivePercentWhenPayFixedAndNotOwnerAndMiltonLosesAndUserEarnsAndDepositIsLowerThanDifferenceBetweenLegs() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(6*10**16);
		ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 5*10**16); 
		MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester mockCase2MiltonDaiProxy, MockCase2MiltonDai mockCase2MiltonDai) = getMockCase2MiltonDai(_admin, address(_daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		(ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(_admin, address(_daiMockedToken), address(_ipTokenDai), address(mockCase2MiltonDai), address(miltonStorageDai), address(stanleyDai));
		address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase2MiltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase2MiltonDai));
		prepareMockCase2MiltonDai(mockCase2MiltonDai, address(mockCase2MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai));
		prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
		prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC
		openSwapPayFixed(_userTwo, block.timestamp, 10000*Constants.D18, 6*10**16, 10*Constants.D18, mockCase2MiltonDai);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), 160*10**16, block.timestamp); // PERCENTAGE_5_18DEC
		int256 openerUserLost = 2990102969109267220 + 10*Constants.D18_INT + 20*Constants.D18_INT - 9967009897030890732780 + 498350494851544536639; // TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_18DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - expectedPayoffAbs + expectedIncomeFeeValue
		// when
		vm.prank(_userTwo); // openerUser
		int256 actualPayoff = mockCase2MiltonDai.itfCalculateSwapPayFixedValue(block.timestamp + 2160000, 1);
		vm.prank(_userThree); // closerUser
		mockCase2MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + 2160000);
		vm.prank(_userThree); // closerUser
		uint256 actualIncomeFeeValue = mockCase2MiltonDai.itfCalculateIncomeFeeValue(actualPayoff);
		// then
		vm.prank(address(miltonStorageDaiProxy));
		MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
		vm.prank(address(miltonStorageDaiProxy));
		(, IporTypes.IporSwapMemory[] memory swaps) = miltonStorageDai.getSwapsPayFixed(_userTwo, 0, 50);
        (,, int256 soap) =  calculateSoap(_userTwo, block.timestamp + 2160000, mockCase2MiltonDai);
		assertEq(0, swaps.length);
		assertEq(actualPayoff, 9967009897030890732780); // expectedPayoff
		assertEq(actualIncomeFeeValue, 498350494851544536639); // expectedIncomeFeeValue
		assertEq(_daiMockedToken.balanceOf(address(mockCase2MiltonDai)), 28000*Constants.D18 + 2990102969109267220 + 10*Constants.D18 - 9967009897030890732780 + 498350494851544536639); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TC_OPENING_FEE_18DEC + TC_IPOR_PUBLICATION_AMOUNT_6DEC - expectedPayoffAbs + expectedIncomeFeeValue
		assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), 10*10**6*Constants.D18_INT + 0 - openerUserLost); // USER_SUPPLY_10MLN_18_DEC + openerUserEarned - openerUserLost
		assertEq(int256(_daiMockedToken.balanceOf(_userThree)), 10*10**6*Constants.D18_INT + 20*Constants.D18_INT - 0); // USER_SUPPLY_10MLN_18_DEC + TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC - closerUserLost
		assertEq(balance.totalCollateralPayFixed, 0); 
		assertEq(balance.iporPublicationFee, 10*10**18);
		assertEq(balance.liquidityPool, 28000*Constants.D18 - 9967009897030890732780 + 2990102969109267220); // TC_LP_BALANCE_BEFORE_CLOSE_18DEC - expectedPayoffWad + TC_OPENING_FEE_18DEC
		assertEq(balance.treasury, 498350494851544536639);
		assertEq(28000*Constants.D18 + 10*10**6*Constants.D18 + 10*10**6*Constants.D18, _daiMockedToken.balanceOf(address(mockCase2MiltonDai))  + _daiMockedToken.balanceOf(_userTwo) + _daiMockedToken.balanceOf(_userThree)); // expectedSumOfBalancesBeforePayout(miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceBeforePayout) vs actualSumOfBalancesBeforePayout(openerUserUnderlyingTokenBalanceBeforePayout + closeUserUnderlyingTokenBalanceAfterPayout + closerUserUnderlyingTokenBalanceAfterPayout + miltonUnderlyingTokenBalanceAfterPayout)
		assertEq(soap, 0);
	}


}