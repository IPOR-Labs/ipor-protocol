// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IporToken.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract IporTokenTest is Test, TestCommons {
    address internal _dao;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _dao = vm.rememberKey(2);
    }

    function testShouldContain18Decimals() public {
        // given
        IporToken iporToken = prepareIporToken();

        // when
        uint256 decimals = iporToken.decimals();

        // then
        assertEq(decimals, TestConstants.TC_DECIMALS_18);
    }

    function testShouldNotSetEthToIporToken() public {
        // given
        IporToken iporToken = prepareIporToken();
        vm.deal(_admin, 1 ether);

        // when & then
        vm.prank(_admin);
        vm.expectRevert();
        payable(address(iporToken)).transfer(0.1 ether);
    }

    function testShouldContainInitially100MlnTokens() public {
        // given
        IporToken iporToken = prepareIporToken();

        // when
        uint256 totalSupply = iporToken.totalSupply();

        // then
        assertEq(totalSupply, TestConstants.TC_100_000_000_18DEC);
    }

    function testShouldContainInitially100MlnTokensInDaoWallet() public {
        // given
        IporToken iporToken = prepareIporToken();

        // when
        uint256 daoBalance = iporToken.balanceOf(_dao);

        // then
        assertEq(daoBalance, TestConstants.TC_100_000_000_18DEC);
    }

    function prepareIporToken() private returns (IporToken) {
        vm.prank(_admin);
        return new IporToken("IporToken", "IPOR", _dao);
    }

}
