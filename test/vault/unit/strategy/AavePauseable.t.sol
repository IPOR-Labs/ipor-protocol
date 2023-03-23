// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {StanleyUtils} from "../../../utils/StanleyUtils.sol";
import "../../../utils/TestConstants.sol";
import "../../../../contracts/amm/MiltonStorage.sol";
import "../../../../contracts/itf/ItfIporOracle.sol";
import "../../../../contracts/tokens/IpToken.sol";
import "../../../../contracts/vault/strategies/StrategyAave.sol";
import "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../../contracts/mocks/tokens/AAVEMockedToken.sol";
import "../../../../contracts/mocks/stanley/aave/aTokens/MockAUsdt.sol";
import "../../../../contracts/mocks/stanley/aave/aTokens/MockAUsdc.sol";
import "../../../../contracts/mocks/stanley/aave/aTokens/MockADai.sol";
import "../../../../contracts/mocks/stanley/aave/MockLendingPoolAave.sol";
import "../../../../contracts/mocks/stanley/aave/MockProviderAave.sol";
import "../../../../contracts/mocks/stanley/aave/MockStakedAave.sol";
import "../../../../contracts/mocks/stanley/aave/MockAaveIncentivesController.sol";

contract AavePausableTest is TestCommons, DataUtils {
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
    StrategyAave internal _strategyAave;

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
        _strategyAave = getStrategyAave(
            address(_usdtMockedToken),
            address(_aUsdtMockedToken),
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

    function testShouldBeAbleToPauseContractWhenSenderIsOwner() public {
        // given
        // when
        _strategyAave.pause();
        // then
        assertTrue(_strategyAave.paused());
    }

    function testShouldBeAbleToUnpauseContractWhenSenderIsOwner() public {
        // given
        _strategyAave.pause();
        assertTrue(_strategyAave.paused());
        // when
        _strategyAave.unpause();
        // then
        assertFalse(_strategyAave.paused());
    }

    function testShouldNotBeAbleToUnpauseContractWhenSenderIsNotOwner() public {
        // given
        _strategyAave.pause();
        assertTrue(_strategyAave.paused());
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyAave.unpause();
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        // when
        _strategyAave.pause();
        // then
        assertTrue(_strategyAave.paused());
        address assetAddress = _strategyAave.getAsset();
        address shareToken = _strategyAave.getShareToken();
        uint256 balance = _strategyAave.balanceOf();
        assertEq(assetAddress, address(_usdtMockedToken));
        assertEq(shareToken, address(_aUsdtMockedToken));
        assertEq(balance, TestConstants.ZERO);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        // when
        _strategyAave.pause();
        // then
        assertTrue(_strategyAave.paused());
        vm.expectRevert("Pausable: paused");
        _strategyAave.deposit(TestConstants.TC_1000_18DEC);
        vm.expectRevert("Pausable: paused");
        _strategyAave.withdraw(TestConstants.TC_1000_18DEC);
        vm.expectRevert("Pausable: paused");
        _strategyAave.beforeClaim();
        vm.expectRevert("Pausable: paused");
        _strategyAave.doClaim();
        vm.expectRevert("Pausable: paused");
        _strategyAave.setStanley(_userTwo);
        vm.expectRevert("Pausable: paused");
        _strategyAave.setTreasuryManager(_userTwo);
        vm.expectRevert("Pausable: paused");
        _strategyAave.setTreasury(_userTwo);
        vm.expectRevert("Pausable: paused");
        _strategyAave.setStkAave(_userTwo);
    }
}
