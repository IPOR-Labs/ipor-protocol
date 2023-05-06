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
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephExchangeRateAndSoap is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            26000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1003093533812002519);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1009368340867602731);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_8_18DEC,
            block.timestamp
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 987823434476506361);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE2;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_7_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_8_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 987823434476506362);
    }

    function testShouldNotCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // BEGIN HACK - subtract liquidity without  burn ipToken
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(55000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        // END HACK - subtract liquidity without  burn ipToken

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        vm.expectRevert("IPOR_316");
        _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8494848805632282803369);
        assertEq(balance.liquidityPool, 5008088573427971608517);
    }

    function testShouldNotCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE3;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(49 * TestConstants.D16);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        // BEGIN HACK - subtract liquidity without  burn ipToken
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(55000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        // END HACK - subtract liquidity without  burn ipToken

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        vm.expectRevert("IPOR_316");
        _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8494848805632282973266);
        assertEq(balance.liquidityPool, 5008088573427971608517);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE3;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(51 * TestConstants.D16);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(55000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertEq(actualExchangeRate, 231204643857984158);
        assertEq(soap, -8864190058051077882738);
        assertEq(balance.liquidityPool, 5008088573427971608517);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(55000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_50_18DEC,
            block.timestamp
        );

        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        // then
        assertEq(actualExchangeRate, 231204643857984155);
        assertEq(soap, -8864190058051077712841);
        assertEq(balance.liquidityPool, 5008088573427971608517);
    }

    function testShouldCalculateExchangeRatePositionValuesAndSoapWhenTwoPayFixedSwapsAreClosedAfter60Days()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            TestConstants.USD_1_000_000_18DEC,
            block.timestamp
        );

        vm.startPrank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_100_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_100_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_4_5_18DEC,
            block.timestamp
        );

        (, , int256 initialSoap) = calculateSoap(_userTwo, block.timestamp, _iporProtocol.milton);
        (, , int256 soapAfter28Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        (, , int256 soapAfter56DaysBeforeClose) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        ExchangeRateAndPayoff memory exchangeRateAndPayoff;
        exchangeRateAndPayoff.initialExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );
        exchangeRateAndPayoff.exchangeRateAfter28Days = _iporProtocol
            .joseph
            .itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        exchangeRateAndPayoff.exchangeRateAfter56DaysBeforeClose = _iporProtocol
            .joseph
            .itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS);
        exchangeRateAndPayoff.payoff1After28Days = _iporProtocol
            .milton
            .itfCalculateSwapPayFixedValue(
                block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS,
                1
            );
        exchangeRateAndPayoff.payoff2After28Days = _iporProtocol
            .milton
            .itfCalculateSwapPayFixedValue(
                block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS,
                2
            );
        exchangeRateAndPayoff.payoff1After56Days = _iporProtocol
            .milton
            .itfCalculateSwapPayFixedValue(
                block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS,
                1
            );
        exchangeRateAndPayoff.payoff2After56Days = _iporProtocol
            .milton
            .itfCalculateSwapPayFixedValue(
                block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS,
                2
            );
        IporTypes.MiltonBalancesMemory memory liquidityPoolBalanceBeforeClose = _iporProtocol
            .miltonStorage
            .getBalance();
        int256 actualSOAPPlusLiquidityPoolBalanceBeforeClose = int256(
            liquidityPoolBalanceBeforeClose.liquidityPool
        ) - soapAfter56DaysBeforeClose;

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(
            1,
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS
        );
        _iporProtocol.milton.itfCloseSwapPayFixed(
            2,
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS
        );

        // then
        (, , int256 soapAfter56DaysAfterClose) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        IporTypes.MiltonBalancesMemory memory liquidityPoolBalanceAfterClose = _iporProtocol
            .miltonStorage
            .getBalance();
        uint256 exchangeRate56DaysAfterClose = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS
        );
        assertEq(initialSoap, TestConstants.ZERO_INT);
        assertEq(exchangeRateAndPayoff.initialExchangeRate, 1000059964010796761);
        assertEq(liquidityPoolBalanceBeforeClose.liquidityPool, 1000059964010796760971708);
        assertEq(soapAfter28Days, 76666315173940979346744);
        assertEq(exchangeRateAndPayoff.exchangeRateAfter28Days, 923393648836855782);
        assertEq(exchangeRateAndPayoff.payoff1After28Days, 38333157586970489673372);
        assertEq(exchangeRateAndPayoff.payoff2After28Days, 38333157586970489673372);
        assertEq(soapAfter56DaysBeforeClose, 153332630347881958693488);
        assertEq(exchangeRateAndPayoff.exchangeRateAfter56DaysBeforeClose, 846727333662914802);
        assertEq(exchangeRateAndPayoff.payoff1After56Days, 76666315173940979346744);
        assertEq(exchangeRateAndPayoff.payoff2After56Days, 76666315173940979346744);
        assertEq(soapAfter56DaysAfterClose, TestConstants.ZERO_INT);
        assertEq(exchangeRate56DaysAfterClose, 846727333662914802);
        assertEq(liquidityPoolBalanceAfterClose.liquidityPool, 846727333662914802278220);
        // SOAP + Liquidity Pool balance before close should be equal to Liquidity Pool balance after close swaps
        assertEq(actualSOAPPlusLiquidityPoolBalanceBeforeClose, 846727333662914802278220);
    }
}
