// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockStrategy} from "contracts/mocks/assetManagement/MockStrategy.sol";
import {AssetManagementDai} from "contracts/vault/AssetManagementDai.sol";
import {AssetManagementUsdc} from "contracts/vault/AssetManagementUsdc.sol";
import {MockTestnetToken} from "contracts/mocks/tokens/MockTestnetToken.sol";
import {IvToken} from "contracts/tokens/IvToken.sol";

contract AssetManagementTotalStrategiesBalanceTest is TestCommons, DataUtils {
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;
    MockStrategy internal _strategyAaveUsdc;
    MockStrategy internal _strategyCompoundUsdc;
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _aDai;
    MockTestnetToken internal _aUsdc;
    MockTestnetToken internal _cDai;
    MockTestnetToken internal _cUsdc;
    AssetManagementDai internal _assetManagementDai;
    AssetManagementUsdc internal _assetManagementUsdc;
    IvToken internal _ivTokenDai;
    IvToken internal _ivTokenUsdc;

    function setUpStrategyDai() public {
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
        _assetManagementDai.setAmmTreasury(_admin);
        _ivTokenDai.setAssetManagement(address(_assetManagementDai));
    }

    function setUpStrategyUsdc() public {
        _strategyAaveUsdc = new MockStrategy();
        _strategyAaveUsdc.setAsset(address(_usdcMockedToken));
        _strategyAaveUsdc.setShareToken(address(_aUsdc));
        _strategyCompoundUsdc = new MockStrategy();
        _strategyCompoundUsdc.setAsset(address(_usdcMockedToken));
        _strategyCompoundUsdc.setShareToken(address(_cUsdc));
        _assetManagementUsdc = getAssetManagementUsdc(
            address(_usdcMockedToken),
            address(_ivTokenUsdc),
            address(_strategyAaveUsdc),
            address(_strategyCompoundUsdc)
        );
        _assetManagementUsdc.setAmmTreasury(_admin);
        _ivTokenUsdc.setAssetManagement(address(_assetManagementUsdc));
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
        _daiMockedToken.approve(address(_assetManagementDai), expectedBalance);
        _strategyAaveDai.setApy(555);
        _strategyCompoundDai.setApy(444);
        _assetManagementDai.deposit(expectedBalance);
        // when
        uint256 actualBalance = _assetManagementDai.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance);
        assertEq(actualBalance, expectedBalance);
    }

    function testShouldReturnBalanceFromCompound18Decimals() public {
        // given
        uint256 expectedBalance = TestConstants.USD_10_000_18DEC;
        _daiMockedToken.approve(address(_assetManagementDai), expectedBalance);
        _strategyAaveDai.setApy(33333333);
        _strategyCompoundDai.setApy(55555555);
        _assetManagementDai.deposit(expectedBalance);
        // when
        uint256 actualBalance = _assetManagementDai.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance);
        assertEq(actualBalance, expectedBalance);
    }

    function testShouldReturnSumOfBalancesFromAaveAndCompoundWhen18Decimals() public {
        // given
        uint256 expectedBalance = TestConstants.USD_20_000_18DEC;
        _daiMockedToken.approve(address(_assetManagementDai), expectedBalance);
        _strategyAaveDai.setApy(33333333);
        _strategyCompoundDai.setApy(55555555);
        _assetManagementDai.deposit(TestConstants.USD_10_000_18DEC);
        _strategyAaveDai.setApy(55555555);
        _strategyCompoundDai.setApy(33333333);
        _assetManagementDai.deposit(TestConstants.USD_10_000_18DEC);
        // when
        uint256 actualBalance = _assetManagementDai.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenDai.balanceOf(_admin);
        assertEq(actualBalance, expectedBalance);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance);
    }

    function testShouldReturnBalanceFromAaveWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_10_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_10_000_6DEC;
        _usdcMockedToken.approve(address(_assetManagementUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApy(555);
        _strategyCompoundUsdc.setApy(444);
        _assetManagementUsdc.deposit(expectedBalance18Decimals);
        // when
        uint256 actualBalance = _assetManagementUsdc.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance18Decimals);
        assertEq(actualBalance, expectedBalance18Decimals);
    }

    function testShouldReturnBalanceFromCompoundWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_10_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_10_000_6DEC;
        _usdcMockedToken.approve(address(_assetManagementUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApy(33333333);
        _strategyCompoundUsdc.setApy(55555555);
        _assetManagementUsdc.deposit(expectedBalance18Decimals);
        // when
        uint256 actualBalance = _assetManagementUsdc.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance18Decimals);
        assertEq(actualBalance, expectedBalance18Decimals);
    }

    function testShouldReturnSumOfBalancesFromAaveAndCompoundWhen6Decimals() public {
        // given
        uint256 expectedBalance18Decimals = TestConstants.USD_20_000_18DEC;
        uint256 expectedBalance6Decimals = TestConstants.USD_20_000_6DEC;
        _usdcMockedToken.approve(address(_assetManagementUsdc), expectedBalance6Decimals);
        _strategyAaveUsdc.setApy(33333333);
        _strategyCompoundUsdc.setApy(55555555);
        _assetManagementUsdc.deposit(TestConstants.USD_10_000_18DEC);
        _strategyAaveUsdc.setApy(55555555);
        _strategyCompoundUsdc.setApy(33333333);
        _assetManagementUsdc.deposit(TestConstants.USD_10_000_18DEC);
        // when
        uint256 actualBalance = _assetManagementUsdc.totalBalance(_admin);
        // then
        uint256 actualAmmTreasuryIvTokenBalance = _ivTokenUsdc.balanceOf(_admin);
        assertEq(actualBalance, expectedBalance18Decimals);
        assertEq(actualAmmTreasuryIvTokenBalance, expectedBalance18Decimals);
    }
}
