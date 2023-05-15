// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {IvToken} from "../../../../contracts/tokens/IvToken.sol";
import {MockTestnetToken} from "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import {MockStrategy} from "../../../../contracts/mocks/stanley/MockStrategy.sol";
import {ItfStanley18D} from "../../../../contracts/itf/ItfStanley18D.sol";

contract StanleyMaxApyStrategyTest is TestCommons, DataUtils {
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    IvToken internal _ivTokenDai;
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;
    ItfStanley18D internal _stanleyDai;

    function _setupStrategies() internal {
        _strategyAaveDai.setAsset(address(_daiMockedToken));
        _strategyAaveDai.setShareToken(address(_daiMockedToken));
        _strategyCompoundDai.setAsset(address(_daiMockedToken));
        _strategyCompoundDai.setShareToken(address(_daiMockedToken));
    }

    function setUp() public {
        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));
        _strategyAaveDai = new MockStrategy();
        _strategyCompoundDai = new MockStrategy();
        _setupStrategies();
        _stanleyDai = getItfStanleyDai(
            address(_daiMockedToken), address(_ivTokenDai), address(_strategyAaveDai), address(_strategyCompoundDai)
        );
        _ivTokenDai.setStanley(address(_stanleyDai));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldSelectAaveStrategy() public {
        // given
        _strategyAaveDai.setApr(100000);
        _strategyCompoundDai.setApr(99999);
        // when
        (address strategyMaxApy,,) = _stanleyDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyAaveDai));
    }

    function testShouldSelectAaveStrategyWhenAaveApyEqualsCompoundApy() public {
        // given
        _strategyAaveDai.setApr(10);
        _strategyCompoundDai.setApr(10);
        // when
        (address strategyMaxApy,,) = _stanleyDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyAaveDai));
    }

    function testShouldSelectCompoundStrategy() public {
        // given
        _strategyAaveDai.setApr(1000);
        _strategyCompoundDai.setApr(99999);
        // when
        (address strategyMaxApy,,) = _stanleyDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyCompoundDai));
    }
}
