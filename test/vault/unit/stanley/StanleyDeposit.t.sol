// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {StrategyAave} from "contracts/vault/strategies/StrategyAave.sol";
import {StrategyCompound} from "contracts/vault/strategies/StrategyCompound.sol";
import {StanleyDai} from "contracts/vault/StanleyDai.sol";
import {MockTestnetToken} from "contracts/mocks/tokens/MockTestnetToken.sol";
import {MockADAI} from "contracts/mocks/stanley/aave/MockADAI.sol";
import {MockCToken} from "contracts/mocks/stanley/compound/MockCToken.sol";
import {AAVEMockedToken} from "contracts/mocks/tokens/AAVEMockedToken.sol";
import {MockComptroller} from "contracts/mocks/stanley/compound/MockComptroller.sol";
import {MockedCOMPToken} from "contracts/mocks/tokens/MockedCOMPToken.sol";
import {MockWhitePaper} from "contracts/mocks/stanley/compound/MockWhitePaper.sol";
import {MockAaveLendingPoolProvider} from "contracts/mocks/stanley/aave/MockAaveLendingPoolProvider.sol";
import {MockAaveLendingPoolCore} from "contracts/mocks/stanley/aave/MockAaveLendingPoolCore.sol";
import {MockAaveLendingPoolV2} from "contracts/mocks/stanley/aave/MockAaveLendingPoolV2.sol";
import {AaveInterestRateMockStrategyV2} from "contracts/mocks/stanley/aave/MockAaveInterestRateStrategyV2.sol";
import {MockAaveStableDebtToken} from "contracts/mocks/stanley/aave/MockAaveStableDebtToken.sol";
import {MockAaveVariableDebtToken} from "contracts/mocks/stanley/aave/MockAaveVariableDebtToken.sol";
import {MockProviderAave} from "contracts/mocks/stanley/aave/MockProviderAave.sol";
import {MockStakedAave} from "contracts/mocks/stanley/aave/MockStakedAave.sol";
import {MockAaveIncentivesController} from "contracts/mocks/stanley/aave/MockAaveIncentivesController.sol";
import {IvToken} from "contracts/tokens/IvToken.sol";

contract StanleyDepositTest is TestCommons, DataUtils {
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
    StanleyDai internal _stanleyDai;
    IvToken internal _ivTokenDai;

    function _setupAave() internal {
        _daiMockedToken.mint(address(_aDaiMockedToken), TestConstants.USD_10_000_18DEC);
        _mockStakedAave.transfer(address(_mockAaveIncentivesController), TestConstants.USD_1_000_18DEC);
        _aaveMockedToken.transfer(address(_mockStakedAave), TestConstants.USD_1_000_18DEC);
        _mockAaveLendingPoolProvider._setLendingPoolCore(address(_mockAaveLendingPoolCore));
        _mockAaveLendingPoolProvider._setLendingPool(address(_lendingPoolAave));
        _mockAaveLendingPoolCore.setReserve(address(_mockAaveInterestRateStrategyV2));
        _mockAaveLendingPoolCore.setReserveCurrentLiquidityRate((TestConstants.RAY_UINT256 / 100) * 2);
        _mockAaveInterestRateStrategyV2.setSupplyRate((TestConstants.RAY_UINT256 / 100) * 2);
        _mockAaveInterestRateStrategyV2.setBorrowRate((TestConstants.RAY_UINT256 / 100) * 3);
        _lendingPoolAave.setStableDebtTokenAddress(address(_mockAaveStableDebtToken));
        _lendingPoolAave.setVariableDebtTokenAddress(address(_mockAaveVariableDebtToken));
        _lendingPoolAave.setInterestRateStrategyAddress(address(_mockAaveInterestRateStrategyV2));
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 2);
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

    function _setupStanley() internal {
        _strategyCompoundDai.setStanley(address(_stanleyDai));
        _strategyAaveDai.setStanley(address(_stanleyDai));
        _ivTokenDai.setStanley(address(_stanleyDai));
        _stanleyDai.setMilton(_admin);
    }

    function _mintTokensForTwoUsersAndApproveStanley() internal {
        _daiMockedToken.mint(_userOne, TestConstants.USD_10_000_18DEC);
        _daiMockedToken.mint(_userTwo, TestConstants.USD_10_000_18DEC);
        vm.prank(_userOne);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        vm.prank(_userTwo);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
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
        _lendingPoolAave = new MockAaveLendingPoolV2(address(_daiMockedToken), address(_aDaiMockedToken));
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
        _mockComptroller = getMockComptroller(
            address(_compMockedToken),
            address(_mockCUSDT),
            address(_mockCUSDC),
            address(_mockCDAI)
        );
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
            address(_daiMockedToken),
            address(_mockCDAI),
            address(_mockComptroller),
            address(_compMockedToken)
        );

        _setupStrategies();

        _stanleyDai = getStanleyDai(
            address(_daiMockedToken),
            address(_ivTokenDai),
            address(_strategyAaveDai),
            address(_strategyCompoundDai)
        );
        _setupStanley();
    }

    function testShouldChangeAaveAPR() public {
        // given
        uint256 apyBefore = _strategyAaveDai.getApr();
        // when
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 5);
        // then
        uint256 apyAfter = _strategyAaveDai.getApr();
        assertEq(apyBefore, 20000000000000000);
        assertEq(apyAfter, 50000000000000000);
    }

    function testShouldChangeCompoundAPR() public {
        // given
        uint256 apyBefore = _strategyCompoundDai.getApr();
        // when
        _mockCDAI.setSupplyRate(uint128(10));
        // then
        uint256 apyAfter = _strategyCompoundDai.getApr();
        assertEq(apyBefore, 69059536870752000);
        assertEq(apyAfter, 21024000);
    }

    function testShouldAcceptDepositAndTransferTokensIntoAave() public {
        // given
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, TestConstants.USD_10_18DEC);
        assertEq(userIvTokenBalance, TestConstants.USD_10_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldAcceptDepositAndTransferTokensIntoCompound() public {
        // given
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        // then
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(compoundBalance, TestConstants.USD_10_18DEC);
        assertEq(userIvTokenBalance, TestConstants.USD_10_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldAcceptDepositsAndTransferTokensIntoAaveTwoTimesWhenOneUserMakesDeposits() public {
        // given
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, TestConstants.USD_20_18DEC);
        assertEq(userIvTokenBalance, TestConstants.USD_20_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldAcceptDepositsAndTransferTokensIntoCompoundTwoTimesWhenOneUserMakesDeposits() public {
        // given
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        // then
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(compoundBalance, 19999999999999999999);
        assertEq(userIvTokenBalance, TestConstants.USD_20_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldAcceptDepositsAndTransferTokensFirstIntoAaveSecondIntoCompoundWhenOneUserMakesDeposits() public {
        // given
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC); // into aave
        _lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC); // into compound
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, TestConstants.USD_10_18DEC);
        assertEq(compoundBalance, TestConstants.USD_20_18DEC);
        assertEq(userIvTokenBalance, 30 * TestConstants.D18);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldAcceptDepositsAndTransferTokensFirstIntoCompoundSecondIntoAaveWhenOneUserMakesDeposits() public {
        // given
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        _stanleyDai.deposit(TestConstants.USD_10_18DEC); // into compound
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC); // into aave
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, TestConstants.USD_20_18DEC);
        assertEq(compoundBalance, TestConstants.USD_10_18DEC);
        assertEq(userIvTokenBalance, 30 * TestConstants.D18);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldTwoDifferentUsersDepositIntoAave() public {
        // given
        _mintTokensForTwoUsersAndApproveStanley();
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        // when
        _stanleyDai.setMilton(_userOne);
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.setMilton(_userTwo);
        vm.prank(_userTwo);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC);
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 userOneIvTokenBalance = _ivTokenDai.balanceOf(_userOne);
        uint256 userTwoIvTokenBalance = _ivTokenDai.balanceOf(_userTwo);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, 30 * TestConstants.D18);
        assertEq(userOneIvTokenBalance, TestConstants.USD_10_18DEC);
        assertEq(userTwoIvTokenBalance, TestConstants.USD_20_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldTwoDifferentUsersDepositIntoCompound() public {
        // given
        _mintTokensForTwoUsersAndApproveStanley();
        // when
        _stanleyDai.setMilton(_userOne);
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.setMilton(_userTwo);
        vm.prank(_userTwo);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC);
        // then
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userOneIvTokenBalance = _ivTokenDai.balanceOf(_userOne);
        uint256 userTwoIvTokenBalance = _ivTokenDai.balanceOf(_userTwo);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(compoundBalance, 30 * TestConstants.D18);
        assertEq(userOneIvTokenBalance, TestConstants.USD_10_18DEC);
        assertEq(userTwoIvTokenBalance, TestConstants.USD_20_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldFirstUserDepositIntoCompoundSecondIntoAave() public {
        // given
        _mintTokensForTwoUsersAndApproveStanley();
        // when
        _stanleyDai.setMilton(_userOne);
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.setMilton(_userTwo);
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        vm.prank(_userTwo);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC);
        // then
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 userOneIvTokenBalance = _ivTokenDai.balanceOf(_userOne);
        uint256 userTwoIvTokenBalance = _ivTokenDai.balanceOf(_userTwo);
        uint256 iporVaultBalance = _daiMockedToken.balanceOf(address(_stanleyDai));
        assertEq(aaveBalance, TestConstants.USD_20_18DEC);
        assertEq(compoundBalance, TestConstants.USD_10_18DEC);
        assertEq(userOneIvTokenBalance, TestConstants.USD_10_18DEC);
        assertEq(userTwoIvTokenBalance, TestConstants.USD_20_18DEC);
        assertEq(iporVaultBalance, TestConstants.ZERO);
    }

    function testShouldNotDepositWhenIsNotMilton() public {
        // given
        _daiMockedToken.mint(_userOne, TestConstants.USD_10_000_18DEC);
        vm.prank(_userOne);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
    }

    function testShouldNotDepositWhenUserTriesToDepositZero() public {
        // given
        _daiMockedToken.mint(_userOne, TestConstants.USD_10_000_18DEC);
        vm.prank(_userOne);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        _stanleyDai.setMilton(_userOne);
        // when
        vm.expectRevert("IPOR_004");
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.ZERO);
    }

    function testShouldCalculateExchangeRate() public {
        // given
        _mintTokensForTwoUsersAndApproveStanley();
        _stanleyDai.setMilton(_userOne);
        vm.prank(_userOne);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC);
        _stanleyDai.setMilton(_userTwo);
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        vm.prank(_userTwo);
        _stanleyDai.deposit(TestConstants.USD_20_18DEC);
        // when
        uint256 exchangeRate = _stanleyDai.calculateExchangeRate();
        // then
        assertEq(exchangeRate, TestConstants.D18);
    }

    function testShouldMigrateAllAssetsFromCompoundToAave() public {
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC); // into Compound
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        // when
        _stanleyDai.migrateAssetToStrategyWithMaxApr();
        // then
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(compoundBalance, TestConstants.ZERO);
        assertEq(aaveBalance, TestConstants.USD_10_18DEC);
        assertEq(userIvTokenBalance, TestConstants.USD_10_18DEC);
    }

    function testShouldMigrateAllAssetsFromAaveToCompound() public {
        _lendingPoolAave.setCurrentLiquidityRate((TestConstants.RAY_UINT128 / 100) * 10);
        _daiMockedToken.approve(address(_stanleyDai), TestConstants.USD_10_000_18DEC);
        _stanleyDai.deposit(TestConstants.USD_10_18DEC); // into Aave
        _lendingPoolAave.setCurrentLiquidityRate(TestConstants.RAY_UINT128 / 100);
        // when
        _stanleyDai.migrateAssetToStrategyWithMaxApr();
        // then
        uint256 compoundBalance = _strategyCompoundDai.balanceOf();
        uint256 aaveBalance = _strategyAaveDai.balanceOf();
        uint256 userIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(compoundBalance, TestConstants.USD_10_18DEC);
        assertEq(aaveBalance, TestConstants.ZERO);
        assertEq(userIvTokenBalance, TestConstants.USD_10_18DEC);
    }
}
