// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IvToken.sol";

contract IvTokenBurnTest is Test, TestCommons {
    IvToken internal _ivToken;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    event Burn(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _ivToken = new IvToken("IvToken", "IVT", address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

	function testShouldNotBurnIvTokenWhenNotStanley () public {
		// given
		// when
		// then
		vm.expectRevert(abi.encodePacked("IPOR_501"));
		_ivToken.burn(_userOne, 1000000000000000000000000);
	}

	function testShouldNotBurnIvTokenWhenAmountIsZero() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("IPOR_504"));
		_ivToken.burn(mockIporVaultAddress, 0);
	}

	function testShouldNotBurnIvTokenWhenZeroAddress() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("ERC20: burn from the zero address"));
		_ivToken.burn(address(0), 1000000000000000000000000);
	}

	function testShouldNotBurnWhenAmountExceedsBalance() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("ERC20: burn amount exceeds balance"));
		_ivToken.burn(mockIporVaultAddress, 1000000000000000000000001);
	}

	function testShouldBurnTokens() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		uint256 amount = 1000000000000000000000000;
		vm.prank(_userOne);
		_ivToken.mint(_userOne, 1000000000000000000000000);
		//when
		// then
		vm.prank(_userOne);
		vm.expectEmit(true, true, false, true);
		emit Transfer(_userOne, address(0), amount);
		vm.expectEmit(true, false, false, true);
		emit Burn(_userOne, amount);
		_ivToken.burn(_userOne, amount);
	}

	function testShouldEmitEvent() public {
		// given
		address mockIporVaultAddress = _admin;
		_ivToken.setStanley(mockIporVaultAddress);
		uint256 amount = 1000000000000000000000000;
		// when
		// then
		_ivToken.mint(_userOne, amount);
		vm.expectEmit(true, false, false, true);
		emit Burn(_userOne, amount);
		_ivToken.burn(_userOne, amount);
	}
}
