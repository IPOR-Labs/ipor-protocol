// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockStrategy} from "../../../../contracts/mocks/stanley/MockStrategy.sol";
import {StanleyDai} from "../../../../contracts/vault/StanleyDai.sol";
import {StanleyUsdc} from "../../../../contracts/vault/StanleyUsdc.sol";
import {MockTestnetToken} from "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import {MockTestnetShareTokenAaveDai} from "../../../../contracts/mocks/tokens/MockTestnetShareTokenAaveDai.sol";
import {MockTestnetShareTokenAaveUsdc} from "../../../../contracts/mocks/tokens/MockTestnetShareTokenAaveUsdc.sol";
import {MockTestnetShareTokenCompoundDai} from "../../../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";
import {MockTestnetShareTokenCompoundUsdc} from
    "../../../../contracts/mocks/tokens/MockTestnetShareTokenCompoundUsdc.sol";
import {IvToken} from "../../../../contracts/tokens/IvToken.sol";

contract StanleyTotalStrategiesBalanceTest is TestCommons, DataUtils {
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;
    MockStrategy internal _strategyAaveUsdc;
    MockStrategy internal _strategyCompoundUsdc;
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetShareTokenAaveDai internal _aDai;
    MockTestnetShareTokenAaveUsdc internal _aUsdc;
    MockTestnetShareTokenCompoundDai internal _cDai;
    MockTestnetShareTokenCompoundUsdc internal _cUsdc;
    StanleyDai internal _stanleyDai;
    StanleyUsdc internal _stanleyUsdc;
    IvToken internal _ivTokenDai;
    IvToken internal _ivTokenUsdc;

    function setUpStrategyDai() public {
        _strategyAaveDai = new MockStrategy();
        _strategyAaveDai.setAsset(address(_daiMockedToken));
        _strategyAaveDai.setShareToken(address(_aDai));
        _strategyCompoundDai = new MockStrategy();
        _strategyCompoundDai.setAsset(address(_daiMockedToken));
        _strategyCompoundDai.setShareToken(address(_cDai));
        _stanleyDai = getStanleyDai(
            address(_daiMockedToken), address(_ivTokenDai), address(_strategyAaveDai), address(_strategyCompoundDai)
        );
        _stanleyDai.setMilton(_admin);
        _ivTokenDai.setStanley(address(_stanleyDai));
    }

    function setUpStrategyUsdc() public {
        _strategyAaveUsdc = new MockStrategy();
        _strategyAaveUsdc.setAsset(address(_usdcMockedToken));
        _strategyAaveUsdc.setShareToken(address(_aUsdc));
        _strategyCompoundUsdc = new MockStrategy();
        _strategyCompoundUsdc.setAsset(address(_usdcMockedToken));
        _strategyCompoundUsdc.setShareToken(address(_cUsdc));
        _stanleyUsdc = getStanleyUsdc(
            address(_usdcMockedToken), address(_ivTokenUsdc), address(_strategyAaveUsdc), address(_strategyCompoundUsdc)
        );
        _stanleyUsdc.setMilton(_admin);
        _ivTokenUsdc.setStanley(address(_stanleyUsdc));
    }

    function setUp() public {
        _daiMockedToken = getTokenDai();
        _usdcMockedToken = getTokenUsdc();
        _aDai = getMockTestnetShareTokenAaveDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _cDai = getMockTestnetShareTokenCompoundDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _aUsdc = getMockTestnetShareTokenAaveUsdc(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _cUsdc = getMockTestnetShareTokenCompoundUsdc(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));
        _ivTokenUsdc = new IvToken("IvToken", "IVT", address(_usdcMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        setUpStrategyDai();
        setUpStrategyUsdc();
    }

    function testShouldReturnBalanceFromAaveWhen18Decimals() public {
        // given
        uint256 expectedBalance = TestConstants.USD_10_000_18DEC;
        _daiMockedToken.approve(address(_stanleyDai), expectedBalance);
        _strategyAaveDai.setApr(555);
        _strategyCompoundDai.setApr(444);
        _stanleyDai.deposit(expectedBalance);
        // when
        uint256 actualBalance = _stanleyDai.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualMiltonIvTokenBalance, expectedBalance);
        assertEq(actualBalance, expectedBalance);
    }

    function testShouldReturnBalanceFromCompound18Decimals() public {
        // given
        uint256 expectedBalance = TestConstants.USD_10_000_18DEC;
        _daiMockedToken.approve(address(_stanleyDai), expectedBalance);
        _strategyAaveDai.setApr(33333333);
        _strategyCompoundDai.setApr(55555555);
        _stanleyDai.deposit(expectedBalance);
        // when
        uint256 actualBalance = _stanleyDai.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualMiltonIvTokenBalance, expectedBalance);
        assertEq(actualBalance, expectedBalance);
    }

    function testShouldReturnSumOfBalancesFromAaveAndCompoundWhen18Decimals() public {
        // given
        uint256 expectedBalance = TestConstants.USD_20_000_18DEC;
        _daiMockedToken.approve(address(_stanleyDai), expectedBalance);
        _strategyAaveDai.setApr(33333333);
        _strategyCompoundDai.setApr(55555555);
        _stanleyDai.deposit(TestConstants.USD_10_000_18DEC);
        _strategyAaveDai.setApr(55555555);
        _strategyCompoundDai.setApr(33333333);
        _stanleyDai.deposit(TestConstants.USD_10_000_18DEC);
        // when
        uint256 actualBalance = _stanleyDai.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualBalance, expectedBalance);
        assertEq(actualMiltonIvTokenBalance, expectedBalance);
    }

    function testShouldReturnBalanceFromAaveWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_10_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_10_000_6DEC;
        _usdcMockedToken.approve(address(_stanleyUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApr(555);
        _strategyCompoundUsdc.setApr(444);
        _stanleyUsdc.deposit(expectedBalance18Decimals);
        // when
        uint256 actualBalance = _stanleyUsdc.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualMiltonIvTokenBalance, expectedBalance18Decimals);
        assertEq(actualBalance, expectedBalance18Decimals);
    }

    function testShouldReturnBalanceFromCompoundWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_10_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_10_000_6DEC;
        _usdcMockedToken.approve(address(_stanleyUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApr(33333333);
        _strategyCompoundUsdc.setApr(55555555);
        _stanleyUsdc.deposit(expectedBalance18Decimals);
        // when
        uint256 actualBalance = _stanleyUsdc.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualMiltonIvTokenBalance, expectedBalance18Decimals);
        assertEq(actualBalance, expectedBalance18Decimals);
    }

    function testShouldReturnSumOfBalancesFromAaveAndCompoundWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_20_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_20_000_6DEC;
        _usdcMockedToken.approve(address(_stanleyUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApr(33333333);
        _strategyCompoundUsdc.setApr(55555555);
        _stanleyUsdc.deposit(TestConstants.USD_10_000_18DEC);
        _strategyAaveUsdc.setApr(55555555);
        _strategyCompoundUsdc.setApr(33333333);
        _stanleyUsdc.deposit(TestConstants.USD_10_000_18DEC);
        // when
        uint256 actualBalance = _stanleyUsdc.totalBalance(_admin);
        // then
        uint256 actualMiltonIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualBalance, expectedBalance18Decimals);
        assertEq(actualMiltonIvTokenBalance, expectedBalance18Decimals);
    }
}
