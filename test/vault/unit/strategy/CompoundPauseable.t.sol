// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {StanleyUtils} from "../../../utils/StanleyUtils.sol";
import "../../../utils/TestConstants.sol";
import "../../../../contracts/amm/MiltonStorage.sol";
import "../../../../contracts/itf/ItfIporOracle.sol";
import "../../../../contracts/tokens/IpToken.sol";
import "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../../contracts/mocks/tokens/MockedCOMPToken.sol";
import "../../../../contracts/mocks/stanley/compound/MockWhitePaper.sol";
import "../../../../contracts/mocks/stanley/compound/MockCToken.sol";
import "../../../../contracts/mocks/stanley/compound/MockComptroller.sol";
import "../../../../contracts/vault/strategies/StrategyCompound.sol";

contract CompoundPausableTest is TestCommons, DataUtils {
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    MockedCOMPToken internal _compMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    MockWhitePaper internal _mockWhitepaper;
    MockCToken internal _mockCUSDT;
    MockCToken internal _mockCUSDC;
    MockCToken internal _mockCDAI;
    MockComptroller internal _mockComptroller;
    StrategyCompound internal _strategyCompound;

    function setUp() public {
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _compMockedToken = getTokenComp();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _mockWhitepaper = getMockWhitePaper();
        _mockCUSDT = getCToken(address(_usdtMockedToken), address(_mockWhitepaper), 6, "cUSDT", "cUSDT");
        _mockCUSDC = getCToken(address(_usdcMockedToken), address(_mockWhitepaper), 6, "cUSDC", "cUSDC");
        _mockCDAI = getCToken(address(_daiMockedToken), address(_mockWhitepaper), 18, "cDAI", "cDAI");
        _mockComptroller =
            getMockComptroller(address(_compMockedToken), address(_mockCUSDT), address(_mockCUSDC), address(_mockCDAI));
        _strategyCompound = getStrategyCompound(
            address(_usdcMockedToken), address(_mockCUSDC), address(_mockComptroller), address(_compMockedToken)
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _strategyCompound.setTreasuryManager(_admin);
        _strategyCompound.setTreasury(_admin);
    }

    function testShouldBeAbleToPauseContractWhenSenderIsOwner() public {
        // given
        // when
        _strategyCompound.pause();
        // then
        assertTrue(_strategyCompound.paused());
    }

    function testShouldBeAbleToUnpauseContractWhenSenderIsOwner() public {
        // given
        _strategyCompound.pause();
        assertTrue(_strategyCompound.paused());
        // when
        _strategyCompound.unpause();
        // then
        assertFalse(_strategyCompound.paused());
    }

    function testShouldNotBeAbleToUnpauseContractWhenSenderIsNotOwner() public {
        // given
        _strategyCompound.pause();
        assertTrue(_strategyCompound.paused());
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyCompound.unpause();
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        // when
        _strategyCompound.pause();
        // then
        assertTrue(_strategyCompound.paused());
        address assetAddress = _strategyCompound.getAsset();
        address shareToken = _strategyCompound.getShareToken();
        uint256 balance = _strategyCompound.balanceOf();
        assertEq(assetAddress, address(_usdcMockedToken));
        assertEq(shareToken, address(_mockCUSDC));
        assertEq(balance, TestConstants.ZERO);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        // when
        _strategyCompound.pause();
        // then
        assertTrue(_strategyCompound.paused());
        vm.expectRevert("Pausable: paused");
        _strategyCompound.deposit(TestConstants.TC_1000_18DEC);
        vm.expectRevert("Pausable: paused");
        _strategyCompound.withdraw(TestConstants.TC_1000_18DEC);
        vm.expectRevert("Pausable: paused");
        _strategyCompound.setBlocksPerDay(7100);
        vm.expectRevert("Pausable: paused");
        _strategyCompound.doClaim();
        vm.expectRevert("Pausable: paused");
        _strategyCompound.setStanley(_userTwo);
        vm.expectRevert("Pausable: paused");
        _strategyCompound.setTreasuryManager(_userTwo);
        vm.expectRevert("Pausable: paused");
        _strategyCompound.setTreasury(_userTwo);
    }
}
