// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "test/TestCommons.sol";
import {TestConstants} from "../utils/TestConstants.sol";
import {MockTestnetStrategy} from "@ipor-protocol/test/mocks/assetManagement/MockTestnetStrategy.sol";
import {MockTestnetToken} from "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";

contract MockStrategyTestnetTest is TestCommons {
    MockTestnetStrategy internal _mockStrategyDai;
    MockTestnetStrategy internal _mockStrategyUsdt;
    MockTestnetStrategy internal _mockStrategyUsdc;
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _shareToken18Decimals;
    MockTestnetToken internal _shareToken6Decimals;

    AssetBuilder internal _assetBuilder = new AssetBuilder(address(this));

    function approveStrategies() public {
        _daiMockedToken.approve(address(_mockStrategyDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        _usdtMockedToken.approve(address(_mockStrategyUsdt), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
        _usdcMockedToken.approve(address(_mockStrategyUsdc), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
    }

    function setInitialAmounts() public {
        deal(address(_daiMockedToken), address(_mockStrategyDai), TestConstants.USER_SUPPLY_10MLN_18DEC);
        deal(address(_usdtMockedToken), address(_mockStrategyUsdt), TestConstants.USER_SUPPLY_6_DECIMALS);
        deal(address(_usdcMockedToken), address(_mockStrategyUsdc), TestConstants.USER_SUPPLY_6_DECIMALS);
        deal(address(_daiMockedToken), _admin, TestConstants.USER_SUPPLY_10MLN_18DEC);
        deal(address(_usdtMockedToken), _admin, TestConstants.USER_SUPPLY_6_DECIMALS);
        deal(address(_usdcMockedToken), _admin, TestConstants.USER_SUPPLY_6_DECIMALS);
    }

    function setUp() public {
        _assetBuilder.withDAI();
        _daiMockedToken = _assetBuilder.build();

        _assetBuilder.withUSDT();
        _usdtMockedToken = _assetBuilder.build();

        _assetBuilder.withUSDC();
        _usdcMockedToken = _assetBuilder.build();

        _assetBuilder.withDAI();
        _shareToken18Decimals = _assetBuilder.build();

        _assetBuilder.withUSDT();
        _shareToken6Decimals = _assetBuilder.build();

        _admin = address(this);

        _mockStrategyDai = getMockTestnetStrategy(address(_daiMockedToken), 18, address(_shareToken18Decimals), _admin);
        _mockStrategyUsdt = getMockTestnetStrategy(address(_usdtMockedToken), 6, address(_shareToken6Decimals), _admin);
        _mockStrategyUsdc = getMockTestnetStrategy(address(_usdcMockedToken), 6, address(_shareToken6Decimals), _admin);

        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        approveStrategies();
        setInitialAmounts();
    }

    function testShouldReturnThreePointFiveAPR() public {
        // when
        uint256 apyDai = _mockStrategyDai.getApy();
        uint256 apyUsdt = _mockStrategyUsdt.getApy();
        uint256 apyUsdc = _mockStrategyUsdc.getApy();
        // then
        assertEq(apyDai, TestConstants.PERCENTAGE_3_5_18DEC);
        assertEq(apyUsdt, TestConstants.PERCENTAGE_3_5_18DEC);
        assertEq(apyUsdc, TestConstants.PERCENTAGE_3_5_18DEC);
    }

    function testShouldDepositIntoStrategyWhen18Decimals() public {
        // given
        uint256 strategyTokenBalanceBefore = _daiMockedToken.balanceOf(address(_mockStrategyDai));
        uint256 strategyBalanceBefore = _mockStrategyDai.balanceOf();
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        // when
        _mockStrategyDai.deposit(depositAmount);
        // then
        uint256 strategyTokenBalanceAfter = _daiMockedToken.balanceOf(address(_mockStrategyDai));
        uint256 strategyBalanceAfter = _mockStrategyDai.balanceOf();
        assertEq(strategyTokenBalanceBefore, TestConstants.USER_SUPPLY_10MLN_18DEC);
        assertEq(strategyTokenBalanceAfter, TestConstants.USER_SUPPLY_10MLN_18DEC + depositAmount);
        assertLt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldDepositIntoStrategyWhen6Decimals() public {
        // given
        uint256 strategyTokenBalanceBefore = _usdtMockedToken.balanceOf(address(_mockStrategyUsdt));
        uint256 strategyBalanceBefore = _mockStrategyUsdt.balanceOf();
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        // when
        _mockStrategyUsdt.deposit(depositAmount);
        // then
        uint256 strategyTokenBalanceAfter = _usdtMockedToken.balanceOf(address(_mockStrategyUsdt));
        uint256 strategyBalanceAfter = _mockStrategyUsdt.balanceOf();
        assertEq(strategyTokenBalanceBefore, TestConstants.USER_SUPPLY_6_DECIMALS);
        assertEq(strategyTokenBalanceAfter, TestConstants.USER_SUPPLY_6_DECIMALS + TestConstants.USD_10_000_6DEC);
        assertLt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldBalanceIncreaseInTime() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyDai.deposit(depositAmount);
        uint256 strategyBalanceBefore = _mockStrategyDai.balanceOf();
        // when
        vm.warp(TestConstants.YEAR_IN_SECONDS);
        // then
        uint256 strategyBalanceAfter = _mockStrategyDai.balanceOf();
        assertLt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldWithdrawFromStrategyWhen18Decimals() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyDai.deposit(depositAmount);
        uint256 strategyTokenBalanceBefore = _daiMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceBefore = _mockStrategyDai.balanceOf();
        vm.warp(TestConstants.YEAR_IN_SECONDS);
        // when
        _mockStrategyDai.withdraw(depositAmount);
        // then
        uint256 strategyTokenBalanceAfter = _daiMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceAfter = _mockStrategyDai.balanceOf();
        assertLt(strategyTokenBalanceBefore, strategyTokenBalanceAfter);
        assertGt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldWithdrawFromStrategyWhen6Decimals() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyUsdc.deposit(depositAmount);
        uint256 strategyTokenBalanceBefore = _usdcMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceBefore = _mockStrategyUsdc.balanceOf();
        vm.warp(TestConstants.YEAR_IN_SECONDS);
        // when
        _mockStrategyUsdc.withdraw(depositAmount);
        // then
        uint256 strategyTokenBalanceAfter = _usdcMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceAfter = _mockStrategyUsdc.balanceOf();
        assertLt(strategyTokenBalanceBefore, strategyTokenBalanceAfter);
        assertGt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldWithdrawMoreThanDeposit6DecimalsWhenInterestWasAdded() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyUsdc.deposit(depositAmount);
        uint256 strategyTokenBalanceBefore = _usdcMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceBefore = _mockStrategyUsdc.balanceOf();
        vm.warp(TestConstants.YEAR_IN_SECONDS);
        // when
        _mockStrategyUsdc.withdraw(depositAmount + TestConstants.USD_100_18DEC);
        // then
        uint256 strategyTokenBalanceAfter = _usdcMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceAfter = _mockStrategyUsdc.balanceOf();
        assertLt(strategyTokenBalanceBefore, strategyTokenBalanceAfter);
        assertGt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldWithdrawMoreThanDeposit18DecimalsWhenInterestWasAdded() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyDai.deposit(depositAmount);
        uint256 strategyTokenBalanceBefore = _daiMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceBefore = _mockStrategyDai.balanceOf();
        vm.warp(TestConstants.YEAR_IN_SECONDS);
        // when
        _mockStrategyDai.withdraw(depositAmount + TestConstants.USD_100_18DEC);
        // then
        uint256 strategyTokenBalanceAfter = _daiMockedToken.balanceOf(address(_admin));
        uint256 strategyBalanceAfter = _mockStrategyDai.balanceOf();
        assertLt(strategyTokenBalanceBefore, strategyTokenBalanceAfter);
        assertGt(strategyBalanceBefore, strategyBalanceAfter);
    }

    function testShouldNotWithdraw6DecimalsWhenNotAssetManagement() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyUsdc.deposit(depositAmount);
        // when
        vm.expectRevert("IPOR_501");
        vm.prank(_userOne);
        _mockStrategyUsdc.withdraw(depositAmount);
    }

    function testShouldNotWithdraw18DecimalsWhenNotAssetManagement() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        _mockStrategyDai.deposit(depositAmount);
        // when
        vm.expectRevert("IPOR_501");
        vm.prank(_userOne);
        _mockStrategyDai.withdraw(depositAmount);
    }

    function testShouldNotDeposit18DecimalsWhenNotAssetManagement() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        // when
        vm.expectRevert("IPOR_501");
        vm.prank(_userOne);
        _mockStrategyDai.deposit(depositAmount);
    }

    function testShouldNotDeposit6DecimalsWhenNotAssetManagement() public {
        // given
        uint256 depositAmount = TestConstants.USD_10_000_18DEC;
        // when
        vm.expectRevert("IPOR_501");
        vm.prank(_userOne);
        _mockStrategyUsdc.deposit(depositAmount);
    }

    function getMockTestnetStrategy(
        address asset,
        uint256 assetDecimals,
        address shareToken,
        address assetManagementProxy
    ) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy(
            asset,
            assetDecimals,
            shareToken,
            assetManagementProxy
        );
        ERC1967Proxy strategyProxy = new ERC1967Proxy(address(strategyImpl), abi.encodeWithSignature("initialize()"));
        return MockTestnetStrategy(address(strategyProxy));
    }
}
