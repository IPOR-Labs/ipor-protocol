// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IvToken.sol";

contract IvTokenMintTest is Test, TestCommons {
    IvToken internal _ivToken;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    event Mint(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _ivToken = new IvToken("IvToken", "IVT", address(0x6B175474E89094C44Da98b954EedeAC495271d0F)); // random address
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

	function testShouldNotMintIvTokenWhenNotStanley () public {
		// given
		// when
		vm.expectRevert(abi.encodePacked("IPOR_501"));
		_ivToken.mint(_userOne, 1*10**18);
	}

	function testShouldNotMintIvTokenWhenAmountIsZero() public {
		// given
		address mockIporVaultAddress = _admin;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		_ivToken.mint(_userOne, 1*10**18);
		vm.expectRevert(abi.encodePacked("IPOR_503"));
		_ivToken.mint(_userOne, 0);
	}

	function testShouldNotMintIvTokenWhenZeroAddress() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		vm.expectRevert(abi.encodePacked("ERC20: mint to the zero address"));
		_ivToken.mint(address(0), 1*10**18);
	}

	function testShouldMintNewTokens() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		uint256 amount = 1*10**18;
		// when
		vm.prank(_userOne);
		vm.expectEmit(true, true, false, true);
		emit Transfer(address(0), _userOne, amount);
		vm.expectEmit(true, false, false, true);
		emit Mint(_userOne, amount);
		_ivToken.mint(_userOne, amount);
	}

	function testShouldEmitMintEvent() public {
		// given
		address mockIporVaultAddress = _admin;
		_ivToken.setStanley(mockIporVaultAddress);
		uint256 amount = 1*10**18;
		uint256 balanceBefore = _ivToken.balanceOf(_userOne);
		// when
		vm.expectEmit(true, false, false, true);
		emit Mint(_userOne, amount);
		_ivToken.mint(_userOne, amount);
		// then
		uint256 balanceAfter = _ivToken.balanceOf(_userOne);
		assertEq(balanceBefore + amount, balanceAfter);
	}
}

