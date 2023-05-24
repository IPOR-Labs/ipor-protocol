// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "contracts/tokens/IpToken.sol";
import "../utils/TestConstants.sol";

contract IpTokenTest is Test, TestCommons {
    address internal _admin;
    address internal _user1;
    address internal _user2;
    address internal _joseph;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    event Mint(address indexed account, uint256 amount);

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
        _joseph = vm.rememberKey(4);
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);
        vm.prank(_user1);
        ipToken.confirmTransferOwnership();

        // then
        assertEq(ipToken.owner(), _user1);
    }

    function testShouldNotTransferOwnershipSenderNotCurrentOwner() public {
        // given - _admin as an initial owner
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        ipToken.transferOwnership(_user1);
    }

    function testShouldNotConfirmTransferOwnershipSenderNotAppointedOwner() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);

        // then
        vm.prank(_user2);
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        ipToken.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceSenderNotAppointedOwner() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);
        vm.prank(_user1);
        ipToken.confirmTransferOwnership();

        // then
        vm.prank(_user1);
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        ipToken.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipSenderAlreadyLostOwnership() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);
        vm.prank(_user1);
        ipToken.confirmTransferOwnership();

        // then
        vm.prank(_admin);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        ipToken.transferOwnership(_user2);
    }

    function testShouldHaveRightsToTransferOwnershipSenderStillHaveRights() public {
        // given
        IpToken ipToken = prepareIpToken();
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);

        // when
        vm.prank(_admin);
        ipToken.transferOwnership(_user1);

        // then
        assertEq(ipToken.owner(), _admin);
    }

    function testShouldNotMintIpTokenIfNotJoseph() public {
        // given - default setJoseph(_joseph)
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_user1);
        vm.expectRevert(abi.encodePacked(AmmErrors.CALLER_NOT_ROUTER));
        ipToken.mint(_user2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
    }

    function testShouldNotMintIpTokenIfZero() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_joseph);
        vm.expectRevert(abi.encodePacked(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        ipToken.mint(_user1, TestConstants.ZERO);
    }

    function testShouldNotBurnIpTokenIfZero() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_joseph);
        vm.expectRevert(abi.encodePacked(AmmPoolsErrors.IP_TOKEN_BURN_AMOUNT_TOO_LOW));
        ipToken.burn(_user1, TestConstants.ZERO);
    }

    function testShouldNotBurnIpTokenIfNotJoseph() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_user1);
        vm.expectRevert(abi.encodePacked(AmmErrors.CALLER_NOT_ROUTER));
        ipToken.burn(_user2, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
    }

    function testShouldEmitEvent() public {
        // given
        uint256 amount = TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC;
        IpToken ipToken = prepareIpToken();

        // when & then
        vm.prank(_joseph);
        vm.expectEmit(true, true, true, true);
        emit Mint(_user1, amount);

        ipToken.mint(_user1, amount);
    }

    function testShouldContain18Decimals() public {
        // given & when
        IpToken ipToken = prepareIpToken();

        // then
        assertEq(ipToken.decimals(), TestConstants.TC_DECIMALS_18);
    }

    function testShouldContainCorrectUnderlyingTokenAddress() public {
        // given
        IpToken ipToken = prepareIpToken();

        // when
        address daiAsset = ipToken.getAsset();

        // then
        assertEq(daiAsset, DAI);
    }

    function testShouldNotSentEthToIpTokenDai() public {
        // given
        IpToken ipToken = prepareIpToken();
        vm.deal(_admin, 1 ether);

        // when & then
        vm.prank(_admin);
        vm.expectRevert();
        payable(address(ipToken)).transfer(0.1 ether);
    }

    function prepareIpToken() private returns (IpToken) {
        vm.startPrank(_admin);
        IpToken ipToken = new IpToken("IpToken", "IPT", DAI);
        ipToken.setJoseph(_joseph);
        vm.stopPrank();
        return ipToken;
    }
}
