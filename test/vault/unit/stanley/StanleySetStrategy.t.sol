// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockStrategy} from "../../../../contracts/mocks/stanley/MockStrategy.sol";
import {StanleyDai} from "../../../../contracts/vault/StanleyDai.sol";
import {MockTestnetToken} from "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import {MockTestnetShareTokenAaveDai} from "../../../../contracts/mocks/tokens/MockTestnetShareTokenAaveDai.sol";
import {MockTestnetShareTokenCompoundDai} from "../../../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";
import {IvToken} from "../../../../contracts/tokens/IvToken.sol";

contract StanleySetStrategyTest is TestCommons, DataUtils {
    MockStrategy internal _strategyAave;
    MockStrategy internal _strategyCompound;
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetShareTokenAaveDai internal _aDai;
    MockTestnetShareTokenCompoundDai internal _cDai;
    StanleyDai internal _stanleyDai;
    IvToken internal _ivTokenDai;

    event StrategyChanged(address changedBy, address oldStrategy, address newStrategy, address newShareToken);

    function setUp() public {
        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _aDai = getMockTestnetShareTokenAaveDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _cDai = getMockTestnetShareTokenCompoundDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));
        _strategyAave = new MockStrategy();
        _strategyAave.setAsset(address(_daiMockedToken));
        _strategyAave.setShareToken(address(_aDai));
        _strategyCompound = new MockStrategy();
        _strategyCompound.setAsset(address(_daiMockedToken));
        _strategyCompound.setShareToken(address(_cDai));
        _stanleyDai = getStanleyDai(
            address(_daiMockedToken), address(_ivTokenDai), address(_strategyAave), address(_strategyCompound)
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _stanleyDai.setMilton(_admin);
        _ivTokenDai.setStanley(address(_stanleyDai));
    }

    function testShouldSetupAaveStrategy() public {
        // given
        MockStrategy newStrategyAave = new MockStrategy();
        newStrategyAave.setShareToken(address(_aDai));
        newStrategyAave.setAsset(address(_daiMockedToken));
        address oldStrategyAddress = address(_strategyAave);
        uint256 newStrategyBalanceBefore = newStrategyAave.balanceOf();
        _aDai.mint(address(_strategyAave), TestConstants.USD_1_000_18DEC);
        _strategyAave.setBalance(TestConstants.USD_1_000_18DEC);
        // when
        vm.expectEmit(true, true, true, true);
        emit StrategyChanged(_admin, address(_strategyAave), address(newStrategyAave), address(_aDai));
        _stanleyDai.setStrategyAave(address(newStrategyAave));
        // then
        uint256 newStrategyBalanceAfter = newStrategyAave.balanceOf();
        assertEq(newStrategyBalanceBefore, newStrategyBalanceAfter);
    }

    function testShouldSetupCompoundStrategy() public {
        // given
        MockStrategy newStrategyCompound = new MockStrategy();
        newStrategyCompound.setShareToken(address(_cDai));
        newStrategyCompound.setAsset(address(_daiMockedToken));
        address oldStrategyAddress = address(_strategyCompound);
        uint256 newStrategyBalanceBefore = newStrategyCompound.balanceOf();
        _cDai.mint(address(_strategyCompound), TestConstants.USD_1_000_18DEC);
        _strategyCompound.setBalance(TestConstants.USD_1_000_18DEC);
        // when
        vm.expectEmit(true, true, true, true);
        emit StrategyChanged(_admin, address(_strategyCompound), address(newStrategyCompound), address(_cDai));
        _stanleyDai.setStrategyCompound(address(newStrategyCompound));
        // then
        uint256 newStrategyBalanceAfter = newStrategyCompound.balanceOf();
        assertEq(newStrategyBalanceBefore, newStrategyBalanceAfter);
    }
}
