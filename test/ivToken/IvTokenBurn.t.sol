// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@ipor-protocol/contracts/libraries/Constants.sol";
import "@ipor-protocol/contracts/tokens/IvToken.sol";

contract IvTokenBurnTest is TestCommons {
    IvToken internal _ivToken;


    event Burn(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _ivToken = new IvToken("IvToken", "IVT", address(0x6B175474E89094C44Da98b954EedeAC495271d0F)); // random address
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

	function testShouldNotBurnIvTokenWhenNotAssetManagement () public {
		// given
		// when
		vm.expectRevert(abi.encodePacked("IPOR_501"));
		_ivToken.burn(_userOne, 1e18);
	}

	function testShouldNotBurnIvTokenWhenAmountIsZero() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setAssetManagement(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("IPOR_504"));
		_ivToken.burn(mockIporVaultAddress, 0);
	}

	function testShouldNotBurnIvTokenWhenZeroAddress() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setAssetManagement(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		vm.expectRevert(abi.encodePacked("ERC20: burn from the zero address"));
		_ivToken.burn(address(0), 1e18);
	}

	function testShouldNotBurnWhenAmountExceedsBalance() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setAssetManagement(mockIporVaultAddress);
		vm.prank(_userOne);
		_ivToken.mint(_userOne, 1e18);
		// when
		vm.prank(_userOne);
		vm.expectRevert(abi.encodePacked("ERC20: burn amount exceeds balance"));
		_ivToken.burn(mockIporVaultAddress, 1e18 + 1);
	}

	function testShouldBurnTokens() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setAssetManagement(mockIporVaultAddress);
		uint256 amount = 1e18;
		vm.prank(_userOne);
		_ivToken.mint(_userOne, 1e18);
		uint256 balanceBefore = _ivToken.balanceOf(_userOne);
		//when
		vm.prank(_userOne);
		vm.expectEmit(true, true, false, true);
		emit Transfer(_userOne, address(0), amount);
		vm.expectEmit(true, false, false, true);
		emit Burn(_userOne, amount);
		_ivToken.burn(_userOne, amount);
		// then
		uint256 balanceAfter = _ivToken.balanceOf(_userOne);
		assertEq(balanceBefore - amount, balanceAfter);
	}

	function testShouldEmitBurnEvent() public {
		// given
		address mockIporVaultAddress = _admin;
		_ivToken.setAssetManagement(mockIporVaultAddress);
		uint256 amount = 1e18;
		// when
		_ivToken.mint(_userOne, amount);
		vm.expectEmit(true, false, false, true);
		emit Burn(_userOne, amount);
		_ivToken.burn(_userOne, amount);
	}
}

