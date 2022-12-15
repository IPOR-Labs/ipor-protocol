
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IvToken";

contract IvTokenTest is Test, TestCommons {
    IvToken internal _ivToken;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    function setUp() public {
        _ivToken = new IvToken();
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }
}
