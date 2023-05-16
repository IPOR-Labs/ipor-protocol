// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import "contracts/vault/strategies/StrategyCompound.sol";
import "contracts/mocks/tokens/MockedCOMPToken.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/stanley/compound/MockCToken.sol";
import "contracts/mocks/stanley/compound/MockComptroller.sol";
import "contracts/mocks/stanley/compound/MockWhitePaper.sol";

contract CompoundStrategyTest is TestCommons, DataUtils {
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    MockedCOMPToken internal _compMockedToken;
    StrategyCompound internal _strategyCompoundUsdc;
    StrategyCompound internal _strategyCompoundUsdt;
    StrategyCompound internal _strategyCompoundDai;
    MockCToken internal _mockCUSDT;
    MockCToken internal _mockCUSDC;
    MockCToken internal _mockCDAI;
    MockComptroller internal _mockComptroller;
    MockWhitePaper internal _mockWhitepaper;

    event StanleyChanged(address changedBy, address oldStanley, address newStanley);

    event BlocksPerYearChanged(address changedBy, uint256 oldBlocksPerYear, uint256 newBlocksPerYear);

    event DoClaim(address indexed claimedBy, address indexed shareToken, address indexed treasury, uint256 amount);

    function _setTreasuries() internal {
        _strategyCompoundUsdc.setTreasury(_admin);
        _strategyCompoundUsdt.setTreasury(_admin);
        _strategyCompoundDai.setTreasury(_admin);
    }

    function setUp() public {
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _compMockedToken = getTokenComp();
        _mockWhitepaper = getMockWhitePaper();
        _mockCUSDT = getCToken(address(_usdtMockedToken), address(_mockWhitepaper), 6, "cUSDT", "cUSDT");
        _mockCUSDC = getCToken(address(_usdcMockedToken), address(_mockWhitepaper), 6, "cUSDC", "cUSDC");
        _mockCDAI = getCToken(address(_daiMockedToken), address(_mockWhitepaper), 18, "cDAI", "cDAI");
        _mockComptroller =
            getMockComptroller(address(_compMockedToken), address(_mockCUSDT), address(_mockCUSDC), address(_mockCDAI));
        _strategyCompoundUsdc = getStrategyCompound(
            address(_usdcMockedToken), address(_mockCUSDC), address(_mockComptroller), address(_compMockedToken)
        );
        _strategyCompoundUsdt = getStrategyCompound(
            address(_usdtMockedToken), address(_mockCUSDT), address(_mockComptroller), address(_compMockedToken)
        );
        _strategyCompoundDai = getStrategyCompound(
            address(_daiMockedToken), address(_mockCDAI), address(_mockComptroller), address(_compMockedToken)
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _setTreasuries();
    }

    function testShouldBeAbleToSetupStanley() public {
        // given
        address newStanleyAddress = _userTwo; // random address
        address oldStanleyAddress = _strategyCompoundDai.getStanley();
        // when
        vm.expectEmit(true, true, true, true);
        emit StanleyChanged(_admin, oldStanleyAddress, newStanleyAddress);
        _strategyCompoundDai.setStanley(newStanleyAddress);
    }

    function testShouldNotBeAbleToSetupStanleyWhenNotOwnerWantsToSetupNewAddress() public {
        // given
        address stanleyAddress = _userTwo;
        // when
        vm.prank(_userOne);
        vm.expectRevert("Ownable: caller is not the owner");
        _strategyCompoundDai.setStanley(stanleyAddress);
    }

    function testShouldBeAbleToSetupStanleyAndInteractWithDai() public {
        // given
        address newStanleyAddress = _userTwo; // random address
        address oldStanleyAddress = _strategyCompoundDai.getStanley();
        vm.expectEmit(true, true, true, true);
        emit StanleyChanged(_admin, oldStanleyAddress, newStanleyAddress);
        _strategyCompoundDai.setStanley(newStanleyAddress);
        deal(address(_daiMockedToken), address(newStanleyAddress), TestConstants.USD_10_000_18DEC);
        vm.startPrank(_userTwo);
        _daiMockedToken.increaseAllowance(address(_strategyCompoundDai), TestConstants.USD_1_000_18DEC);
        // when
        _strategyCompoundDai.deposit(TestConstants.USD_500_18DEC);
        assertEq(_daiMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_9_500_18DEC);
        _strategyCompoundDai.withdraw(TestConstants.USD_500_18DEC);
        assertEq(_daiMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_10_000_18DEC);
        vm.stopPrank();
    }

    function testShouldBeAbleToSetupStanleyAndInteractWithUsdt() public {
        // given
        address newStanleyAddress = _userTwo; // random address
        address oldStanleyAddress = _strategyCompoundUsdt.getStanley();
        vm.expectEmit(true, true, true, true);
        emit StanleyChanged(_admin, oldStanleyAddress, newStanleyAddress);
        _strategyCompoundUsdt.setStanley(newStanleyAddress);
        deal(address(_usdtMockedToken), address(newStanleyAddress), TestConstants.USD_10_000_6DEC);
        vm.startPrank(_userTwo);
        _usdtMockedToken.increaseAllowance(address(_strategyCompoundUsdt), TestConstants.USD_1_000_6DEC);
        // when
        _strategyCompoundUsdt.deposit(TestConstants.USD_1_000_18DEC);
        assertEq(_usdtMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_9_000_6DEC);
        assertEq(_mockCUSDT.balanceOf(address(_strategyCompoundUsdt)), 754533916);
        _strategyCompoundUsdt.withdraw(TestConstants.USD_1_000_18DEC);
        assertEq(_usdtMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_10_000_6DEC);
        assertEq(_mockCUSDT.balanceOf(address(_strategyCompoundUsdt)), TestConstants.ZERO);
    }

    function testShouldBeAbleToSetupStanleyAndInteractWithUsdc() public {
        // given
        address newStanleyAddress = _userTwo; // random address
        address oldStanleyAddress = _strategyCompoundUsdc.getStanley();
        vm.expectEmit(true, true, true, true);
        emit StanleyChanged(_admin, oldStanleyAddress, newStanleyAddress);
        _strategyCompoundUsdc.setStanley(newStanleyAddress);
        deal(address(_usdcMockedToken), address(newStanleyAddress), TestConstants.USD_10_000_6DEC);
        vm.startPrank(_userTwo);
        _usdcMockedToken.increaseAllowance(address(_strategyCompoundUsdc), TestConstants.USD_1_000_6DEC);
        // when
        _strategyCompoundUsdc.deposit(TestConstants.USD_1_000_18DEC);
        assertEq(_usdcMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_9_000_6DEC);
        assertEq(_mockCUSDC.balanceOf(address(_strategyCompoundUsdc)), 754533916);
        _strategyCompoundUsdc.withdraw(TestConstants.USD_1_000_18DEC);
        assertEq(_usdcMockedToken.balanceOf(newStanleyAddress), TestConstants.USD_10_000_6DEC);
        assertEq(_mockCUSDC.balanceOf(address(_strategyCompoundUsdc)), TestConstants.ZERO);
    }

    function testShouldNotBeAbleToSetupTreasuryAaveStrategyWhenSenderIsNotTreasuryManager() public {
        vm.expectRevert("IPOR_505");
        vm.prank(_userOne);
        _strategyCompoundUsdc.setTreasury(address(0));
    }

    function testShouldNotBeAbleToSetupTreasuryManagerStrategyWhenSenderIsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyCompoundUsdc.setTreasuryManager(address(0));
    }

    function testShouldSetupNewBlocksPerYear() public {
        // when
        vm.expectEmit(true, true, true, true);
        emit BlocksPerYearChanged(_admin, 2102400, 2102500);
        _strategyCompoundDai.setBlocksPerYear(2102500);
    }

    function testShouldNotSetupNewBlocksPerYearToZero() public {
        // when
        vm.expectRevert("IPOR_004");
        _strategyCompoundDai.setBlocksPerYear(TestConstants.ZERO);
    }

    function testShouldBeAbleDoClaim() public {
        // when
        vm.expectEmit(true, true, true, true);
        emit DoClaim(_admin, address(_mockCDAI), _admin, TestConstants.ZERO);
        _strategyCompoundDai.doClaim();
    }

    function testShouldNotBeAbleDoClaimWhenNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyCompoundDai.doClaim();
    }

    function testShouldNotSetupNewBlocksPerYearWhenNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        _strategyCompoundDai.setBlocksPerYear(2102500);
    }
}
