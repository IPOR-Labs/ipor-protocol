// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {AssetManagementUtils} from "../../../utils/AssetManagementUtils.sol";
import "../../../utils/TestConstants.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/vault/strategies/StrategyAave.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/tokens/AAVEMockedToken.sol";
import "contracts/mocks/assetManagement/aave/aTokens/MockAUsdt.sol";
import "contracts/mocks/assetManagement/aave/aTokens/MockAUsdc.sol";
import "contracts/mocks/assetManagement/aave/aTokens/MockADai.sol";
import "contracts/mocks/assetManagement/aave/MockLendingPoolAave.sol";
import "contracts/mocks/assetManagement/aave/MockProviderAave.sol";
import "contracts/mocks/assetManagement/aave/MockStakedAave.sol";
import "contracts/mocks/assetManagement/aave/MockAaveIncentivesController.sol";

contract AaveStrategyAaveMocksTest is TestCommons, DataUtils {
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    AAVEMockedToken internal _aaveMockedToken;
    MockAUsdt internal _aUsdtMockedToken;
    MockAUsdc internal _aUsdcMockedToken;
    MockADai internal _aDaiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    MockLendingPoolAave internal _lendingPoolAave;
    MockProviderAave internal _mockProviderAave;
    MockStakedAave internal _mockStakedAave;
    MockAaveIncentivesController internal _mockAaveIncentivesController;
    StrategyAave internal _strategyAaveUsdt;
    StrategyAave internal _strategyAaveUsdc;
    StrategyAave internal _strategyAaveDai;

    event AssetManagementChanged(address changedBy, address oldAssetManagement, address newAssetManagement);

    function setUp() public {
        vm.warp(1000 * 24 * 60 * 60);
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _aaveMockedToken = getTokenAave();
        _aUsdtMockedToken = getTokenAUsdt();
        _aUsdcMockedToken = getTokenAUsdc();
        _aDaiMockedToken = getTokenADai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _lendingPoolAave = getMockLendingPoolAave(
            address(_daiMockedToken),
            address(_aDaiMockedToken),
            100000,
            address(_usdcMockedToken),
            address(_aUsdcMockedToken),
            200000,
            address(_usdtMockedToken),
            address(_aUsdtMockedToken),
            200000
        );
        _mockProviderAave = getMockProviderAave(address(_lendingPoolAave));
        _mockStakedAave = getMockStakedAave(address(_aaveMockedToken));
        _mockAaveIncentivesController = getMockAaveIncentivesController(address(_mockStakedAave));
        _strategyAaveUsdt = getStrategyAave(
            address(_usdtMockedToken),
            address(_aUsdtMockedToken),
            address(_mockProviderAave),
            address(_mockStakedAave),
            address(_mockAaveIncentivesController),
            address(_aaveMockedToken)
        );
        _strategyAaveUsdc = getStrategyAave(
            address(_usdcMockedToken),
            address(_aUsdcMockedToken),
            address(_mockProviderAave),
            address(_mockStakedAave),
            address(_mockAaveIncentivesController),
            address(_aaveMockedToken)
        );
        _strategyAaveDai = getStrategyAave(
            address(_daiMockedToken),
            address(_aDaiMockedToken),
            address(_mockProviderAave),
            address(_mockStakedAave),
            address(_mockAaveIncentivesController),
            address(_aaveMockedToken)
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldBeAbleToSetupAssetManagementAndInteractWithDAI() public {
        // given
        address newAssetManagementAddress = _userTwo; // random address
        address oldAssetManagementAddress = _strategyAaveDai.getAssetManagement();
        vm.expectEmit(true, true, true, true);
        emit AssetManagementChanged(_admin, oldAssetManagementAddress, newAssetManagementAddress);
        _strategyAaveDai.setAssetManagement(newAssetManagementAddress);
        deal(address(_daiMockedToken), address(newAssetManagementAddress), TestConstants.USD_10_000_18DEC);
        vm.startPrank(_userTwo);
        _daiMockedToken.increaseAllowance(address(_strategyAaveDai), TestConstants.USD_10_000_18DEC);
        _strategyAaveDai.deposit(TestConstants.USD_1_000_18DEC);
        assertEq(_daiMockedToken.balanceOf(newAssetManagementAddress), TestConstants.TC_9_000_USD_18DEC);
        assertEq(_aDaiMockedToken.balanceOf(address(_strategyAaveDai)), TestConstants.USD_1_000_18DEC);
        _strategyAaveDai.withdraw(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        assertEq(_daiMockedToken.balanceOf(newAssetManagementAddress), TestConstants.USD_10_000_18DEC);
        assertEq(_aDaiMockedToken.balanceOf(address(_strategyAaveDai)), TestConstants.ZERO);
    }

    function testShouldBeAbleToSetupAssetManagementAndInteractWithUSDC() public {
        // given
        address newAssetManagementAddress = _userTwo; // random address
        address oldAssetManagementAddress = _strategyAaveUsdc.getAssetManagement();
        vm.expectEmit(true, true, true, true);
        emit AssetManagementChanged(_admin, oldAssetManagementAddress, newAssetManagementAddress);
        _strategyAaveUsdc.setAssetManagement(newAssetManagementAddress);
        deal(address(_usdcMockedToken), address(newAssetManagementAddress), TestConstants.USD_10_000_6DEC);
        vm.startPrank(_userTwo);
        _usdcMockedToken.increaseAllowance(address(_strategyAaveUsdc), TestConstants.USD_10_000_6DEC);
        _strategyAaveUsdc.deposit(TestConstants.USD_1_000_18DEC);
        assertEq(_usdcMockedToken.balanceOf(newAssetManagementAddress), TestConstants.USD_9_000_6DEC);
        assertEq(_aUsdcMockedToken.balanceOf(address(_strategyAaveUsdc)), TestConstants.USD_1_000_6DEC);
        _strategyAaveUsdc.withdraw(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        assertEq(_usdcMockedToken.balanceOf(newAssetManagementAddress), TestConstants.USD_10_000_6DEC);
        assertEq(_aUsdcMockedToken.balanceOf(address(_strategyAaveUsdc)), TestConstants.ZERO);
    }

    function testShouldBeAbleToSetupAssetManagementAndInteractWithUSDT() public {
        // given
        address newAssetManagementAddress = _userTwo; // random address
        address oldAssetManagementAddress = _strategyAaveUsdt.getAssetManagement();
        vm.expectEmit(true, true, true, true);
        emit AssetManagementChanged(_admin, oldAssetManagementAddress, newAssetManagementAddress);
        _strategyAaveUsdt.setAssetManagement(newAssetManagementAddress);
        deal(address(_usdtMockedToken), address(newAssetManagementAddress), TestConstants.USD_10_000_6DEC);
        vm.startPrank(_userTwo);
        _usdtMockedToken.increaseAllowance(address(_strategyAaveUsdt), TestConstants.USD_10_000_6DEC);
        _strategyAaveUsdt.deposit(TestConstants.USD_1_000_18DEC);
        assertEq(_usdtMockedToken.balanceOf(newAssetManagementAddress), TestConstants.USD_9_000_6DEC);
        assertEq(_aUsdtMockedToken.balanceOf(address(_strategyAaveUsdt)), TestConstants.USD_1_000_6DEC);
        _strategyAaveUsdt.withdraw(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        assertEq(_usdtMockedToken.balanceOf(newAssetManagementAddress), TestConstants.USD_10_000_6DEC);
        assertEq(_aUsdtMockedToken.balanceOf(address(_strategyAaveUsdt)), TestConstants.ZERO);
    }
}
