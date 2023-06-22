// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@ipor-protocol/test/TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {AssetManagementUtils} from "../../../utils/AssetManagementUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import "@ipor-protocol/contracts/vault/strategies/StrategyAave.sol";
import "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import "@ipor-protocol/test/mocks/tokens/AAVEMockedToken.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockAUsdt.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockAUsdc.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockADai.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockLendingPoolAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockProviderAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockStakedAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveIncentivesController.sol";

contract AaveStrategyTest is TestCommons, DataUtils {
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    AAVEMockedToken internal _aaveMockedToken;
    MockAUsdt internal _aUsdtMockedToken;
    MockAUsdc internal _aUsdcMockedToken;
    MockADai internal _aDaiMockedToken;
    MockLendingPoolAave internal _lendingPoolAave;
    MockProviderAave internal _mockProviderAave;
    MockStakedAave internal _mockStakedAave;
    MockAaveIncentivesController internal _mockAaveIncentivesController;
    StrategyAave internal _strategyAaveDai;

    event AssetManagementChanged(address newAssetManagement);

    event DoBeforeClaim(address indexed executedBy, address[] shareTokens);

    event DoClaim(address indexed claimedBy, address indexed shareToken, address indexed treasury, uint256 amount);

    event StkAaveChanged(address newStkAave);

    function setUp() public {
        vm.warp(1000 * 24 * 60 * 60);
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _aaveMockedToken = getTokenAave();
        _aUsdtMockedToken = getTokenAUsdt();
        _aUsdcMockedToken = getTokenAUsdc();
        _aDaiMockedToken = getTokenADai();
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
        _strategyAaveDai.setTreasury(_userTwo);
    }

    function testShouldBeAbleToSetupAssetManagement() public {
        // given
        address newAssetManagementAddress = _userTwo; // random address
        address oldAssetManagementAddress = _strategyAaveDai.getAssetManagement();
        // when
        vm.expectEmit(true, true, true, true);
        emit AssetManagementChanged(newAssetManagementAddress);
        _strategyAaveDai.setAssetManagement(newAssetManagementAddress);
    }

    function testShouldNotBeAbleToSetupAssetManagementWhenNonOwnerWantsToSetupNewAddress() public {
        // given
        address newAssetManagementAddress = _userTwo;
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyAaveDai.setAssetManagement(newAssetManagementAddress);
    }

    function testShouldNotBeAbleToSetupTreasuryAaveStrategy() public {
        vm.expectRevert("IPOR_502");
        _strategyAaveDai.setTreasury(address(0));
    }

    function testShouldNotBeAbleToSetupTreasuryAaveStrategyWhenSenderIsNotTreasuryManager() public {
        vm.expectRevert("IPOR_505");
        vm.prank(_userOne);
        _strategyAaveDai.setTreasury(address(0));
    }

    function testShouldNotBeAbleToSetupTreasuryManagerAaveStrategy() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyAaveDai.setTreasuryManager(address(0));
    }

    function testShouldBeAbleDoBeforeClaim() public {
        // when
        vm.expectEmit(true, true, true, true);
        address[] memory shareTokens = new address[](1);
        shareTokens[0] = address(_aDaiMockedToken);
        emit DoBeforeClaim(_admin, shareTokens);
        _strategyAaveDai.beforeClaim();
    }

    function testShouldBeAbleDoClaim() public {
        // when
        vm.expectEmit(true, true, true, true);
        emit DoClaim(_admin, address(_aDaiMockedToken), _userTwo, TestConstants.ZERO);
        _strategyAaveDai.doClaim();
    }

    function testShouldBeAbleToSetStkAaveAddress() public {
        // when
        vm.expectEmit(true, true, true, true);
        emit StkAaveChanged(address(_admin));
        _strategyAaveDai.setStkAave(address(_admin));
    }
}
