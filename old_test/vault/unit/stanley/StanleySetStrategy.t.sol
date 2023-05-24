// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockStrategy} from "contracts/mocks/assetManagement/MockStrategy.sol";
import {AssetManagementDai} from "contracts/vault/AssetManagementDai.sol";
import {MockTestnetToken} from "contracts/mocks/tokens/MockTestnetToken.sol";
import {IvToken} from "contracts/tokens/IvToken.sol";

contract AssetManagementSetStrategyTest is TestCommons, DataUtils {
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _aDai;
    MockTestnetToken internal _cDai;
    AssetManagementDai internal _assetManagementDai;
    IvToken internal _ivTokenDai;

    event StrategyChanged(address changedBy, address oldStrategy, address newStrategy, address newShareToken);

    function setUp() public {
        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _aDai = getMockTestnetShareTokenAaveDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _cDai = getMockTestnetShareTokenCompoundDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));
        _strategyAaveDai = new MockStrategy();
        _strategyAaveDai.setAsset(address(_daiMockedToken));
        _strategyAaveDai.setShareToken(address(_aDai));
        _strategyCompoundDai = new MockStrategy();
        _strategyCompoundDai.setAsset(address(_daiMockedToken));
        _strategyCompoundDai.setShareToken(address(_cDai));
        _assetManagementDai = getAssetManagementDai(
            address(_daiMockedToken),
            address(_ivTokenDai),
            address(_strategyAaveDai),
            address(_strategyCompoundDai)
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _assetManagementDai.setAmmTreasury(_admin);
        _ivTokenDai.setAssetManagement(address(_assetManagementDai));
    }

    function testShouldSetupAaveStrategy() public {
        // given
        MockStrategy newStrategyAaveDai = new MockStrategy();
        newStrategyAaveDai.setShareToken(address(_aDai));
        newStrategyAaveDai.setAsset(address(_daiMockedToken));
        uint256 newStrategyBalanceBefore = newStrategyAaveDai.balanceOf();
        _aDai.mint(address(_strategyAaveDai), TestConstants.USD_1_000_18DEC);
        _strategyAaveDai.setBalance(TestConstants.USD_1_000_18DEC);
        // when
        vm.expectEmit(true, true, true, true);
        emit StrategyChanged(_admin, address(_strategyAaveDai), address(newStrategyAaveDai), address(_aDai));
        _assetManagementDai.setStrategyAave(address(newStrategyAaveDai));
        // then
        uint256 newStrategyBalanceAfter = newStrategyAaveDai.balanceOf();
        assertEq(newStrategyBalanceBefore, newStrategyBalanceAfter);
    }

    function testShouldSetupAaveStrategyWhenBalanceOnStrategyIsZero() public {
        // given
        MockStrategy newStrategyAaveDai = new MockStrategy();
        newStrategyAaveDai.setShareToken(address(_aDai));
        newStrategyAaveDai.setAsset(address(_daiMockedToken));
        uint256 oldStrategyBalanceBefore = _strategyAaveDai.balanceOf();
        uint256 newStrategyBalanceBefore = newStrategyAaveDai.balanceOf();
        // when
        vm.expectEmit(true, true, true, true);
        emit StrategyChanged(_admin, address(_strategyAaveDai), address(newStrategyAaveDai), address(_aDai));
        _assetManagementDai.setStrategyAave(address(newStrategyAaveDai));
        // then
        uint256 oldStrategyBalanceAfter = _strategyAaveDai.balanceOf();
        uint256 newStrategyBalanceAfter = newStrategyAaveDai.balanceOf();
        assertEq(oldStrategyBalanceBefore, TestConstants.ZERO);
        assertEq(oldStrategyBalanceAfter, TestConstants.ZERO);
        assertEq(newStrategyBalanceBefore, TestConstants.ZERO);
        assertEq(newStrategyBalanceAfter, TestConstants.ZERO);
        assertEq(address(_assetManagementDai.getStrategyAave()), address(newStrategyAaveDai));
    }

    function testShouldNotSetupNewStrategyAaveWhenUnderlyingTokenDoesNotMatch() public {
        // given
        MockStrategy newStrategyAaveDai = new MockStrategy();
        newStrategyAaveDai.setShareToken(address(_aDai));
        newStrategyAaveDai.setAsset(address(_usdtMockedToken));
        // when
        vm.expectRevert("IPOR_500");
        _assetManagementDai.setStrategyAave(address(newStrategyAaveDai));
    }

    function testShouldNotSetupNewStrategyAaveWhenZeroAddress() public {
        // given
        // when
        vm.expectRevert("IPOR_000");
        _assetManagementDai.setStrategyAave(address(0));
    }

    function testShouldSetupCompoundStrategy() public {
        // given
        MockStrategy newStrategyCompoundDai = new MockStrategy();
        newStrategyCompoundDai.setShareToken(address(_cDai));
        newStrategyCompoundDai.setAsset(address(_daiMockedToken));
        uint256 newStrategyBalanceBefore = newStrategyCompoundDai.balanceOf();
        _cDai.mint(address(_strategyCompoundDai), TestConstants.USD_1_000_18DEC);
        _strategyCompoundDai.setBalance(TestConstants.USD_1_000_18DEC);
        // when
        vm.expectEmit(true, true, true, true);
        emit StrategyChanged(_admin, address(_strategyCompoundDai), address(newStrategyCompoundDai), address(_cDai));
        _assetManagementDai.setStrategyCompound(address(newStrategyCompoundDai));
        // then
        uint256 newStrategyBalanceAfter = newStrategyCompoundDai.balanceOf();
        assertEq(newStrategyBalanceBefore, newStrategyBalanceAfter);
    }

    function testShouldNotSetupNewStrategyCompoundWhenUnderlyingTokenDoesNotMatch() public {
        // given
        MockStrategy newStrategyCompoundDai = new MockStrategy();
        newStrategyCompoundDai.setShareToken(address(_cDai));
        newStrategyCompoundDai.setAsset(address(_usdtMockedToken));
        // when
        vm.expectRevert("IPOR_500");
        _assetManagementDai.setStrategyCompound(address(newStrategyCompoundDai));
    }

    function testShouldNotSetupNewStrategyCompoundWhenZeroAddress() public {
        // given
        // when
        vm.expectRevert("IPOR_000");
        _assetManagementDai.setStrategyCompound(address(0));
    }
}
