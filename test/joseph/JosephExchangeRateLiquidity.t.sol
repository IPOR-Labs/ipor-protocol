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

contract JosephExchangeRateLiquidity is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
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
                TestConstants.ZERO,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceAndIpTokenTotalSupplyIsZero()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd6Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            block.timestamp
        );

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        _iporProtocol.miltonStorage.setJoseph(_userOne);
        vm.prank(_userOne);
        _iporProtocol.miltonStorage.subtractLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, TestConstants.ZERO);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And18Decimals() public {
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
        _iporProtocol.joseph.itfProvideLiquidity(40 * TestConstants.D18, block.timestamp);

        // open position to have something in the pool
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            40 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, 1000074977506747976);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsZeroAnd18Decimals()
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

        //BEGIN HACK - provide liquidity without mint ipToken
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.addLiquidity(
            _liquidityProvider,
            TestConstants.USD_2_000_18DEC,
            TestConstants.USD_20_000_000_18DEC,
            TestConstants.USD_10_000_000_18DEC
        );
        _iporProtocol.asset.transfer(address(_iporProtocol.milton), TestConstants.USD_2_000_18DEC);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        //END HACK - provide liquidity without mint ipToken

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ipToken)), TestConstants.ZERO);
        assertGt(balance.liquidityPool, TestConstants.ZERO);
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And6Decimals() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(40 * TestConstants.N1__0_6DEC, block.timestamp);

        // open position to have something in the pool
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            40 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // then
        assertEq(actualExchangeRate, 1000074977506747976);
    }
}
