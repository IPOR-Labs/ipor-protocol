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
        _ivToken = new IvToken("IvToken", "IVT", address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

	function testShouldNotMintIvTokenWhenNotStanley () public {
		// given
		// when
		// then
		vm.expectRevert(abi.encodePacked("IPOR_501"));
		_ivToken.mint(_userOne, 1000000000000000000000000);
	}

	function testShouldNotMintIvTokenWhenAmountIsZero() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("IPOR_503"));
		_ivToken.mint(mockIporVaultAddress, 0);
	}

	function testShouldNotMintIvTokenWhenZeroAddress() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectRevert(abi.encodePacked("ERC20: mint to the zero address"));
		_ivToken.mint(address(0), 1000000000000000000000000);
	}

	function testShouldMintNewTokens() public {
		// given
		address mockIporVaultAddress = _userOne;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		vm.prank(_userOne);
		// then
		vm.expectEmit(true, true, false, true);
		emit Transfer(address(0), mockIporVaultAddress, 1000000000000000000000000);
		vm.expectEmit(true, false, false, true);
		emit Mint(mockIporVaultAddress, 1000000000000000000000000);
		_ivToken.mint(mockIporVaultAddress, 1000000000000000000000000);
	}

	function testShouldEmitEvent() public {
		// given
		address mockIporVaultAddress = _admin;
		_ivToken.setStanley(mockIporVaultAddress);
		// when
		// then
		vm.expectEmit(true, false, false, true);
		emit Mint(_userOne, 1000000000000000000000000);
		_ivToken.mint(_userOne, 1000000000000000000000000);
	}
}

