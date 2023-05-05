// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephRedeem is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.TestCaseConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldRedeemIpToken18DecimalsSimpleCase1() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalances.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalances.expectedTokenBalance
        );
    }

    function testShouldRedeemIpToken6DecimalsSimpleCase1() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalances.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalances.expectedTokenBalance
        );
    }

    function testShouldRedeemIpTokensBecauseNoValidationForCoolOffPeriod() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalances.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalances.expectedTokenBalance
        );
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpTokensWhenTwoTimesProvidedLiquidity() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 70 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 6000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9994000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 6000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 6000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            block.timestamp
        );
        _iporProtocol.joseph.itfProvideLiquidity(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            block.timestamp
        );

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_14_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalances.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalances.expectedMiltonBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalances.expectedTokenBalance
        );
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    //
    //    function testShouldRedeemIpDaiAndIpUsdtWhenSimpleCase1() public {
    //        // given
    //
    //        ItfIporOracle _iporProtocol.iporOracleDai = getIporOracleAsset(
    //            _userOne,
    //            address(_iporProtocol.asset),
    //            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
    //        );
    //        ItfIporOracle _iporProtocol.iporOracleUsdt = getIporOracleAsset(
    //            _userOne,
    //            address(_iporProtocol.asset),
    //            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
    //        );
    //        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_iporProtocol.asset));
    //        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_iporProtocol.asset));
    //        MiltonStorage miltonStorageDai = getMiltonStorage();
    //        MiltonStorage miltonStorageUsdt = getMiltonStorage();
    //        MockCase0MiltonDai _iporProtocol.milton = getMockCase0MiltonDai(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.iporOracleDai),
    //            address(miltonStorageDai),
    //            address(_miltonSpreadModel),
    //            address(stanleyDai)
    //        );
    //        MockCase0MiltonUsdt _iporProtocol.milton = getMockCase0MiltonUsdt(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.iporOracleUsdt),
    //            address(miltonStorageUsdt),
    //            address(_miltonSpreadModel),
    //            address(stanleyUsdt)
    //        );
    //        MockCase0JosephDai _iporProtocol.joseph = getMockCase0JosephDai(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.ipToken),
    //            address(_iporProtocol.milton),
    //            address(miltonStorageDai),
    //            address(stanleyDai)
    //        );
    //        MockCase0JosephUsdt _iporProtocol.joseph = getMockCase0JosephUsdt(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.ipToken),
    //            address(_iporProtocol.milton),
    //            address(miltonStorageUsdt),
    //            address(stanleyUsdt)
    //        );
    //        uint256 redeemFee18Dec = 50 * TestConstants.D18;
    //        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
    //        ExpectedJosephBalances memory expectedBalancesDai;
    //        expectedBalancesDai.expectedIpTokenBalance = 4000 * TestConstants.D18;
    //        expectedBalancesDai.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee18Dec;
    //        expectedBalancesDai.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
    //        expectedBalancesDai.expectedLiquidityPoolBalance =
    //            4000 *
    //            TestConstants.D18 +
    //            redeemFee18Dec;
    //        ExpectedJosephBalances memory expectedBalancesUsdt;
    //        expectedBalancesUsdt.expectedIpTokenBalance = 4000 * TestConstants.D18;
    //        expectedBalancesUsdt.expectedTokenBalance =
    //            9996000 *
    //            TestConstants.N1__0_6DEC -
    //            redeemFee6Dec;
    //        expectedBalancesUsdt.expectedMiltonBalance =
    //            4000 *
    //            TestConstants.N1__0_6DEC +
    //            redeemFee6Dec;
    //        expectedBalancesUsdt.expectedLiquidityPoolBalance =
    //            4000 *
    //            TestConstants.D18 +
    //            redeemFee18Dec;
    //        prepareApproveForUsersDai(
    //            _users,
    //            _iporProtocol.asset,
    //            address(_iporProtocol.joseph),
    //            address(_iporProtocol.milton)
    //        );
    //        prepareApproveForUsersUsd(
    //            _users,
    //            _iporProtocol.asset,
    //            address(_iporProtocol.joseph),
    //            address(_iporProtocol.milton)
    //        );
    //        prepareMilton(_iporProtocol.milton, address(_iporProtocol.joseph), address(stanleyDai));
    //        prepareMilton(_iporProtocol.milton, address(_iporProtocol.joseph), address(stanleyUsdt));
    //        prepareJoseph(_iporProtocol.joseph);
    //        prepareJoseph(_iporProtocol.joseph);
    //        prepareIpToken(_iporProtocol.ipToken, address(_iporProtocol.joseph));
    //        prepareIpToken(_iporProtocol.ipToken, address(_iporProtocol.joseph));
    //        vm.startPrank(_liquidityProvider);
    //        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
    //        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
    //        // when
    //        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
    //        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
    //        vm.stopPrank();
    //        IporTypes.MiltonBalancesMemory memory balanceDai = _iporProtocol.milton.getAccruedBalance();
    //        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
    //        IporTypes.MiltonBalancesMemory memory balanceUsdt = _iporProtocol.milton.getAccruedBalance();
    //        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;
    //        // then
    //        assertEq(
    //            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
    //            expectedBalancesDai.expectedIpTokenBalance
    //        );
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
    //            expectedBalancesDai.expectedMiltonBalance
    //        );
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(_liquidityProvider),
    //            expectedBalancesDai.expectedTokenBalance
    //        );
    //        assertEq(actualLiquidityPoolBalanceDai, expectedBalancesDai.expectedLiquidityPoolBalance);
    //        assertEq(
    //            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
    //            expectedBalancesUsdt.expectedIpTokenBalance
    //        );
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
    //            expectedBalancesUsdt.expectedMiltonBalance
    //        );
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(_liquidityProvider),
    //            expectedBalancesUsdt.expectedTokenBalance
    //        );
    //        assertEq(actualLiquidityPoolBalanceUsdt, expectedBalancesUsdt.expectedLiquidityPoolBalance);
    //    }
    //
    //    function testShouldRedeemIpDaiAndIpUsdtWhenTwoUsersAndSimpleCase1() public {
    //        // given
    //        ItfIporOracle _iporProtocol.iporOracleDai = getIporOracleAsset(
    //            _userOne,
    //            address(_iporProtocol.asset),
    //            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
    //        );
    //        ItfIporOracle _iporProtocol.iporOracleUsdt = getIporOracleAsset(
    //            _userOne,
    //            address(_iporProtocol.asset),
    //            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
    //        );
    //        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_iporProtocol.asset));
    //        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_iporProtocol.asset));
    //        MiltonStorage miltonStorageDai = getMiltonStorage();
    //        MiltonStorage miltonStorageUsdt = getMiltonStorage();
    //        MockCase0MiltonDai _iporProtocol.milton = getMockCase0MiltonDai(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.iporOracleDai),
    //            address(miltonStorageDai),
    //            address(_miltonSpreadModel),
    //            address(stanleyDai)
    //        );
    //        MockCase0MiltonUsdt _iporProtocol.milton = getMockCase0MiltonUsdt(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.iporOracleUsdt),
    //            address(miltonStorageUsdt),
    //            address(_miltonSpreadModel),
    //            address(stanleyUsdt)
    //        );
    //        MockCase0JosephDai _iporProtocol.joseph = getMockCase0JosephDai(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.ipToken),
    //            address(_iporProtocol.milton),
    //            address(miltonStorageDai),
    //            address(stanleyDai)
    //        );
    //        MockCase0JosephUsdt _iporProtocol.joseph = getMockCase0JosephUsdt(
    //            address(_iporProtocol.asset),
    //            address(_iporProtocol.ipToken),
    //            address(_iporProtocol.milton),
    //            address(miltonStorageUsdt),
    //            address(stanleyUsdt)
    //        );
    //        uint256 redeemFee18Dec = 50 * TestConstants.D18;
    //        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
    //        ExpectedJosephBalances memory expectedBalancesDai;
    //        expectedBalancesDai.expectedIpTokenBalance = 4000 * TestConstants.D18;
    //        expectedBalancesDai.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee18Dec;
    //        expectedBalancesDai.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
    //        expectedBalancesDai.expectedLiquidityPoolBalance =
    //            4000 *
    //            TestConstants.D18 +
    //            redeemFee18Dec;
    //        ExpectedJosephBalances memory expectedBalancesUsdt;
    //        expectedBalancesUsdt.expectedIpTokenBalance = 4000 * TestConstants.D18;
    //        expectedBalancesUsdt.expectedTokenBalance =
    //            9996000 *
    //            TestConstants.N1__0_6DEC -
    //            redeemFee6Dec;
    //        expectedBalancesUsdt.expectedMiltonBalance =
    //            4000 *
    //            TestConstants.N1__0_6DEC +
    //            redeemFee6Dec;
    //        expectedBalancesUsdt.expectedLiquidityPoolBalance =
    //            4000 *
    //            TestConstants.D18 +
    //            redeemFee18Dec;
    //        prepareApproveForUsersDai(
    //            _users,
    //            _iporProtocol.asset,
    //            address(_iporProtocol.joseph),
    //            address(_iporProtocol.milton)
    //        );
    //        prepareApproveForUsersUsd(
    //            _users,
    //            _iporProtocol.asset,
    //            address(_iporProtocol.joseph),
    //            address(_iporProtocol.milton)
    //        );
    //        prepareMilton(_iporProtocol.milton, address(_iporProtocol.joseph), address(stanleyDai));
    //        prepareMilton(_iporProtocol.milton, address(_iporProtocol.joseph), address(stanleyUsdt));
    //        prepareJoseph(_iporProtocol.joseph);
    //        prepareJoseph(_iporProtocol.joseph);
    //        prepareIpToken(_iporProtocol.ipToken, address(_iporProtocol.joseph));
    //        prepareIpToken(_iporProtocol.ipToken, address(_iporProtocol.joseph));
    //        vm.prank(_userOne);
    //        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
    //        vm.prank(_userTwo);
    //        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
    //        // when
    //        vm.prank(_userOne);
    //        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
    //        vm.prank(_userTwo);
    //        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
    //        IporTypes.MiltonBalancesMemory memory balanceDai = _iporProtocol.milton.getAccruedBalance();
    //        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
    //        IporTypes.MiltonBalancesMemory memory balanceUsdt = _iporProtocol.milton.getAccruedBalance();
    //        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;
    //        // then
    //        assertEq(_iporProtocol.ipToken.balanceOf(_userOne), expectedBalancesDai.expectedIpTokenBalance);
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
    //            expectedBalancesDai.expectedMiltonBalance
    //        );
    //        assertEq(_iporProtocol.asset.balanceOf(_userOne), expectedBalancesDai.expectedTokenBalance);
    //        assertEq(balanceDai.liquidityPool, expectedBalancesDai.expectedLiquidityPoolBalance);
    //        assertEq(_iporProtocol.ipToken.balanceOf(_userTwo), expectedBalancesUsdt.expectedIpTokenBalance);
    //        assertEq(
    //            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
    //            expectedBalancesUsdt.expectedMiltonBalance
    //        );
    //        assertEq(_iporProtocol.asset.balanceOf(_userTwo), expectedBalancesUsdt.expectedTokenBalance);
    //        assertEq(balanceUsdt.liquidityPool, expectedBalancesUsdt.expectedLiquidityPoolBalance);
    //    }

    function testShouldRedeemWhenLiquidityProviderCanTransferTokensToAnotherUserAndUserCanRedeemTokens()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalancesLiquidityProvider;
        expectedBalancesLiquidityProvider.expectedIpTokenBalance = 400 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedTokenBalance = 9989600 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedMiltonBalance =
            400 *
            TestConstants.D18 +
            redeemFee;
        expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance =
            400 *
            TestConstants.D18 +
            redeemFee;

        ExpectedJosephBalances memory expectedBalancesUserThree;
        expectedBalancesUserThree.expectedIpTokenBalance = TestConstants.ZERO;
        expectedBalancesUserThree.expectedTokenBalance = 10010000 * TestConstants.D18 - redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_400_18DEC, block.timestamp);
        _iporProtocol.ipToken.transfer(_userThree, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);

        // when
        vm.stopPrank();
        vm.prank(_userThree);
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalancesLiquidityProvider.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalancesLiquidityProvider.expectedMiltonBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalancesLiquidityProvider.expectedTokenBalance
        );
        assertEq(
            actualLiquidityPoolBalance,
            expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance
        );
        assertEq(
            _iporProtocol.ipToken.balanceOf(_userThree),
            expectedBalancesUserThree.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(_userThree),
            expectedBalancesUserThree.expectedTokenBalance
        );
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndPayFixed() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(51000 * TestConstants.D18, block.timestamp);

        // then

        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndReceiveFixed() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            40000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(51000 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenPayFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            48000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);
        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(10300 * TestConstants.D18, block.timestamp);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenReceiveFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            48000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);

        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(10300 * TestConstants.D18, block.timestamp);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }
}
