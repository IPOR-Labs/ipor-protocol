// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {StrategyAave} from "@ipor-protocol/contracts/vault/strategies/StrategyAave.sol";
import {StrategyCompound} from "@ipor-protocol/contracts/vault/strategies/StrategyCompound.sol";
import {MockStrategy} from "@ipor-protocol/test/mocks/assetManagement/MockStrategy.sol";
import {AssetManagementDai} from "@ipor-protocol/contracts/vault/AssetManagementDai.sol";
import {AssetManagementUsdc} from "@ipor-protocol/contracts/vault/AssetManagementUsdc.sol";
import {MockTestnetToken} from "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import {MockADAI} from "@ipor-protocol/test/mocks/assetManagement/aave/MockADAI.sol";
import {MockCToken} from "@ipor-protocol/test/mocks/assetManagement/compound/MockCToken.sol";
import {AAVEMockedToken} from "@ipor-protocol/test/mocks/tokens/AAVEMockedToken.sol";
import {MockComptroller} from "@ipor-protocol/test/mocks/assetManagement/compound/MockComptroller.sol";
import {MockedCOMPToken} from "@ipor-protocol/test/mocks/tokens/MockedCOMPToken.sol";
import {MockWhitePaper} from "@ipor-protocol/test/mocks/assetManagement/compound/MockWhitePaper.sol";
import {MockAaveLendingPoolProvider} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveLendingPoolProvider.sol";
import {MockAaveLendingPoolCore} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveLendingPoolCore.sol";
import {MockAaveLendingPoolV2} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveLendingPoolV2.sol";
import {AaveInterestRateMockStrategyV2} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveInterestRateStrategyV2.sol";
import {MockAaveStableDebtToken} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveStableDebtToken.sol";
import {MockAaveVariableDebtToken} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveVariableDebtToken.sol";
import {MockProviderAave} from "@ipor-protocol/test/mocks/assetManagement/aave/MockProviderAave.sol";
import {MockStakedAave} from "@ipor-protocol/test/mocks/assetManagement/aave/MockStakedAave.sol";
import {MockAaveIncentivesController} from "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveIncentivesController.sol";
import {IvToken} from "@ipor-protocol/contracts/tokens/IvToken.sol";

contract AssetManagementWithdrawTest is TestCommons, DataUtils {
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockADAI internal _aDaiMockedToken;
    MockCToken internal _mockCDAI;
    MockCToken internal _mockCUSDT;
    MockCToken internal _mockCUSDC;
    MockComptroller internal _mockComptroller;
    MockWhitePaper internal _mockWhitepaper;
    AAVEMockedToken internal _aaveMockedToken;
    MockedCOMPToken internal _compMockedToken;
	MockAaveLendingPoolProvider internal _mockAaveLendingPoolProvider;
	MockAaveLendingPoolCore internal _mockAaveLendingPoolCore;
    MockAaveLendingPoolV2 internal _lendingPoolAave;
	AaveInterestRateMockStrategyV2 internal _mockAaveInterestRateStrategyV2;
	MockAaveStableDebtToken internal _mockAaveStableDebtToken;
	MockAaveVariableDebtToken internal _mockAaveVariableDebtToken;
    MockProviderAave internal _mockProviderAave;
    MockStakedAave internal _mockStakedAave;
    MockAaveIncentivesController internal _mockAaveIncentivesController;
    StrategyAave internal _strategyAaveDai;
    StrategyCompound internal _strategyCompoundDai;
    AssetManagementDai internal _assetManagementDai;
    IvToken internal _ivTokenDai;

	uint128 public constant TC_AAVE_CURRENT_LIQUIDITY_RATE = TestConstants.RAY_UINT128 / 100 * 10;

	function _setupAave() internal {
		_daiMockedToken.mint(address(_aDaiMockedToken), TestConstants.USD_10_000_18DEC);
		_mockStakedAave.transfer(address(_mockAaveIncentivesController), TestConstants.USD_1_000_18DEC);
		_aaveMockedToken.transfer(address(_mockStakedAave), TestConstants.USD_1_000_18DEC);
		_mockAaveLendingPoolProvider._setLendingPoolCore(address(_mockAaveLendingPoolCore));
		_mockAaveLendingPoolProvider._setLendingPool(address(_lendingPoolAave));
		_mockAaveLendingPoolCore.setReserve(address(_mockAaveInterestRateStrategyV2));
		_mockAaveLendingPoolCore.setReserveCurrentLiquidityRate(TestConstants.RAY_UINT256 / 100 * 2);
		_mockAaveInterestRateStrategyV2.setSupplyRate(TestConstants.RAY_UINT256 / 100 * 2);
		_mockAaveInterestRateStrategyV2.setBorrowRate(TestConstants.RAY_UINT256 / 100 * 3);
		_lendingPoolAave.setStableDebtTokenAddress(address(_mockAaveStableDebtToken));
		_lendingPoolAave.setVariableDebtTokenAddress(address(_mockAaveVariableDebtToken));
		_lendingPoolAave.setInterestRateStrategyAddress(address(_mockAaveInterestRateStrategyV2));
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100 * 2);
		_aDaiMockedToken.transfer(address(_lendingPoolAave), TestConstants.USD_1_000_18DEC);
	}

	function _setupCompound() internal {
		_compMockedToken.transfer(address(_mockComptroller), TestConstants.USD_1_000_18DEC);
	}

	function _setupStrategies() internal {
		_strategyAaveDai.setTreasuryManager(_admin);
		_strategyCompoundDai.setTreasury(_userTwo);
		_strategyAaveDai.setTreasuryManager(_admin);
		_strategyCompoundDai.setTreasury(_userTwo);
	}

	function _setupAssetManagement() internal {
		_strategyCompoundDai.setAssetManagement(address(_assetManagementDai));
		_strategyAaveDai.setAssetManagement(address(_assetManagementDai));
		_ivTokenDai.setAssetManagement(address(_assetManagementDai));
		_assetManagementDai.setAmmTreasury(_admin);
	}

	function _mintTokensForTwoUsersAndApproveAssetManagement() internal {
		_daiMockedToken.mint(_userOne, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.mint(_userTwo, TestConstants.USD_10_000_18DEC);
		vm.prank(_userOne);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		vm.prank(_userTwo);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
	}

    function setUp() public {

        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);

        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();

        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));

        vm.warp(1000 * 24 * 60 * 60);

		_aDaiMockedToken = getMockADAI(address(_daiMockedToken), _admin);
        _aaveMockedToken = getTokenAave();
        _lendingPoolAave = new MockAaveLendingPoolV2(
			address(_daiMockedToken),
			address(_aDaiMockedToken)
        );
        _mockStakedAave = getMockStakedAave(address(_aaveMockedToken));
		_mockAaveLendingPoolProvider = new MockAaveLendingPoolProvider();
		_mockAaveLendingPoolCore = new MockAaveLendingPoolCore();
		_mockAaveInterestRateStrategyV2 = new AaveInterestRateMockStrategyV2();
		_mockAaveStableDebtToken = new MockAaveStableDebtToken(TestConstants.ZERO, TestConstants.ZERO);
		_mockAaveVariableDebtToken = new MockAaveVariableDebtToken(TestConstants.ZERO);
        _mockProviderAave = getMockProviderAave(address(_lendingPoolAave));
        _mockAaveIncentivesController = getMockAaveIncentivesController(address(_mockStakedAave));

		_setupAave();

        _mockWhitepaper = getMockWhitePaper();
        _mockComptroller =
            getMockComptroller(address(_compMockedToken), address(_mockCUSDT), address(_mockCUSDC), address(_mockCDAI));
        _mockCDAI = getCToken(address(_daiMockedToken), address(_mockWhitepaper), 18, "cDAI", "cDAI");
        _compMockedToken = getTokenComp();

		_setupCompound();

        _strategyAaveDai = getStrategyAave(
            address(_daiMockedToken),
            address(_aDaiMockedToken),
            address(_mockProviderAave),
			address(_mockStakedAave),
            address(_mockAaveIncentivesController),
            address(_aaveMockedToken)
        );
        _strategyCompoundDai = getStrategyCompound(
            address(_daiMockedToken), address(_mockCDAI), address(_mockComptroller), address(_compMockedToken)
        );

		_setupStrategies();

        _assetManagementDai = getAssetManagementDai(
            address(_daiMockedToken), address(_ivTokenDai), address(_strategyAaveDai), address(_strategyCompoundDai)
        );
		_setupAssetManagement();
    }

	function testShouldWithdrawFromAaveWhenOnlyAaveHasFundsAndAaveHasMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaveBalanceBefore = _strategyAaveDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(aaveBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 aaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaveBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromAaveWhenOnlyAaveHasFundsAndAaveDoesNotHaveMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaveBalanceBefore = _strategyAaveDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(aaveBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 1000);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 aaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaveBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawPartOfFundsFromAaveWhenOnlyAaveHasFundsAndAaveHasMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaveBalanceBefore = _strategyAaveDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(aaveBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		// when
		_assetManagementDai.withdraw(6 * TestConstants.D18);
		// then
		uint256 aaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaveBalanceAfter, 4 * TestConstants.D18);
		assertEq(userIvTokenAfter, 4 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromAaveWhenOnlyAaveHasFundsAndAaveDoesNotHaveMaxApyCase2() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaveBalanceBefore = _strategyAaveDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(aaveBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 1000);
		// when
		_assetManagementDai.withdraw(7 * TestConstants.D18);
		// then
		uint256 aaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaveBalanceAfter, 3 * TestConstants.D18);
		assertEq(userIvTokenAfter, 3 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenOnlyCompoundHasFundsAndCompoundHasMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(compoundBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenOnlyCompoundHasFundsAndCompoundDoesNotHaveMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(compoundBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawPartOfFundsFromCompoundWhenOnlyCompoundHasFundsAndCompoundHasMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		// when
		_assetManagementDai.withdraw(6 * TestConstants.D18);
		// then
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(compoundBalanceAfter, 4 * TestConstants.D18);
		assertEq(userIvTokenAfter, 4 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenOnlyCompoundHasFundsAndCompoundDoesNotHaveMaxApyCase2() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(7 * TestConstants.D18);
		// then
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(compoundBalanceAfter, 3 * TestConstants.D18);
		assertEq(userIvTokenAfter, 3 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromAaveWhenDepositToBothButCompoundHasMaxApy() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenBefore, 30 * TestConstants.D18);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, TestConstants.ZERO);
		assertEq(compoundBalanceAfter, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenAfter, TestConstants.USD_20_18DEC);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenDepositToBothButCompoundHasMaxApy() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, TestConstants.USD_10_18DEC);
		// decrease AAVE APR
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenBefore, 30 * TestConstants.D18);
		// when
		_assetManagementDai.withdraw(15 * TestConstants.D18);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, TestConstants.USD_10_18DEC);
		assertEq(compoundBalanceAfter, 5 * TestConstants.D18);
		assertEq(userIvTokenAfter, 15 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenDepositToBothButAaveHasMaxApy() public {
		// given
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(aaaveBalanceBefore, TestConstants.USD_10_18DEC);
		assertEq(userIvTokenBefore, 30 * TestConstants.D18);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, TestConstants.USD_10_18DEC);
		assertEq(compoundBalanceAfter, 10000000000000000001);
		assertEq(userIvTokenAfter, TestConstants.USD_20_18DEC);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromAaveWhenDepositToBothButAaveHasMaxApyButInCompoundHasLessBalance() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(40 * TestConstants.D18);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, 40 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenBefore, 60 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(25 * TestConstants.D18);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, 15 * TestConstants.D18);
		assertEq(compoundBalanceAfter, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenAfter, 35 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldNotWithdrawWhenHasLessTokens() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, TestConstants.USD_10_18DEC);
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(userIvTokenBefore, TestConstants.USD_10_18DEC);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_20_18DEC);
		// then
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
	}

	function testShouldWithdrawAllFromAaveAndCompound() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(TestConstants.USD_10_18DEC);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, TestConstants.USD_10_18DEC);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenBefore, 30 * TestConstants.D18);
		// when
		_assetManagementDai.withdrawAll();
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, TestConstants.ZERO);
		assertEq(compoundBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, TestConstants.ZERO);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenDepositToBothButAaveHasMaxApyCase2() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(40 * TestConstants.D18);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, 40 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(TestConstants.USD_20_18DEC);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, TestConstants.USD_20_18DEC);
		assertEq(userIvTokenBefore, 60 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(TestConstants.USD_10_18DEC);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, 40 * TestConstants.D18);
		assertEq(compoundBalanceAfter, 10000000000000000001);
		assertEq(userIvTokenAfter, 50 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawDaiFromAaveWhenNotAllInOneStrategyAndDepositToBothButAaveHasMaxApy() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(40 * TestConstants.D18);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, 40 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(40 * TestConstants.D18);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, 40 * TestConstants.D18);
		assertEq(userIvTokenBefore, 80 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(50 * TestConstants.D18);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, TestConstants.ZERO);
		assertEq(compoundBalanceAfter, 40 * TestConstants.D18);
		assertEq(userIvTokenAfter, 40 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawUsdcFromAaveWhenNotAllInOneStrategyAndDepositToBothButAaveHasMaxApy() public {
		// given
		MockTestnetToken usdcMockedToken = getTokenUsdc();
		IvToken ivTokenUsdc = new IvToken("IvToken", "IVT", address(usdcMockedToken));
		MockStrategy strategyAaveUsdc = new MockStrategy();
		strategyAaveUsdc.setShareToken(address(usdcMockedToken));
		strategyAaveUsdc.setAsset(address(usdcMockedToken));
		MockStrategy strategyCompoundUsdc = new MockStrategy();
		strategyCompoundUsdc.setShareToken(address(usdcMockedToken));
		strategyCompoundUsdc.setAsset(address(usdcMockedToken));
		AssetManagementUsdc assetManagementUsdc = getAssetManagementUsdc(
            address(usdcMockedToken), address(ivTokenUsdc), address(strategyAaveUsdc), address(strategyCompoundUsdc)
        );
		ivTokenUsdc.setAssetManagement(address(assetManagementUsdc));
		assetManagementUsdc.setAmmTreasury(_admin);
		usdcMockedToken.approve(_admin, TestConstants.USD_10_000_6DEC);
		usdcMockedToken.approve(address(assetManagementUsdc), TestConstants.USD_10_000_6DEC);
		strategyAaveUsdc.setApy(3 * TestConstants.D18);
		assetManagementUsdc.deposit(40 * TestConstants.D18);
		uint256 aaaveBalanceBefore = strategyAaveUsdc.balanceOf();
		assertEq(aaaveBalanceBefore, 40 * TestConstants.D18);
		strategyCompoundUsdc.setApy(4 * TestConstants.D18);
		assetManagementUsdc.deposit(40 * TestConstants.D18);
		uint256 compoundBalanceBefore = strategyCompoundUsdc.balanceOf();
		uint256 userIvTokenBefore = ivTokenUsdc.balanceOf(_admin);
		assertEq(compoundBalanceBefore, 40 * TestConstants.D18);
		assertEq(userIvTokenBefore, 80 * TestConstants.D18);
		strategyAaveUsdc.setApy(5 * TestConstants.D18);
		// when
		assetManagementUsdc.withdraw(50 * TestConstants.D18);
		// then
		uint256 aaaveBalanceAfter = strategyAaveUsdc.balanceOf();
		uint256 compoundBalanceAfter = strategyCompoundUsdc.balanceOf();
		uint256 userIvTokenAfter = ivTokenUsdc.balanceOf(_admin);
		uint256 iporVaultBalance = usdcMockedToken.balanceOf(address(assetManagementUsdc));
		assertEq(aaaveBalanceAfter, TestConstants.ZERO);
		assertEq(compoundBalanceAfter, 40 * TestConstants.D18);
		assertEq(userIvTokenAfter, 40 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

	function testShouldWithdrawFromCompoundWhenNotAllAmountInOneStrategyAndDepositToBothButAaveHasMaxApy() public {
		// given
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		_daiMockedToken.approve(_admin, TestConstants.USD_10_000_18DEC);
		_daiMockedToken.approve(address(_assetManagementDai), TestConstants.USD_10_000_18DEC);
		_assetManagementDai.deposit(30 * TestConstants.D18);
		uint256 aaaveBalanceBefore = _strategyAaveDai.balanceOf();
		assertEq(aaaveBalanceBefore, 30 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
		_assetManagementDai.deposit(40 * TestConstants.D18);
		uint256 compoundBalanceBefore = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenBefore = _ivTokenDai.balanceOf(_admin);
		assertEq(compoundBalanceBefore, 40 * TestConstants.D18);
		assertEq(userIvTokenBefore, 70 * TestConstants.D18);
		_lendingPoolAave.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
		// when
		_assetManagementDai.withdraw(50 * TestConstants.D18);
		// then
		uint256 aaaveBalanceAfter = _strategyAaveDai.balanceOf();
		uint256 compoundBalanceAfter = _strategyCompoundDai.balanceOf();
		uint256 userIvTokenAfter = _ivTokenDai.balanceOf(_admin);
		uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_assetManagementDai));
		assertEq(aaaveBalanceAfter, 30 * TestConstants.D18);
		assertEq(compoundBalanceAfter, TestConstants.ZERO);
		assertEq(userIvTokenAfter, 30 * TestConstants.D18);
		assertEq(iporVaultBalance, TestConstants.ZERO);
	}

}
