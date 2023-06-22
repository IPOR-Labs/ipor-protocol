// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@ipor-protocol/contracts/libraries/Constants.sol";
import "@ipor-protocol/contracts/tokens/IvToken.sol";
import "@ipor-protocol/contracts/mocks/tokens/MockTestnetToken.sol";

contract IvTokenTest is TestCommons {
    IvToken internal _ivToken;
    MockTestnetToken internal _mockTestnetTokenDai;


    function setUp() public {
        _ivToken = new IvToken("IvToken", "IVT", address(0x6B175474E89094C44Da98b954EedeAC495271d0F)); // random address
        _mockTestnetTokenDai = new MockTestnetToken("Mocked DAI", "DAI", 1e18, 18);
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

    function testShouldNotBeAbleToSetupVaultAddressWhenNotOwner() public {
        // given
        vm.prank(_userOne);
        // when
        // then
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _ivToken.setAssetManagement(address(0x6B175474E89094C44Da98b954EedeAC495271d0F)); // random address
    }

    function testShouldIvTokenContain18Decimals() public {
        // given
        uint8 decimals = _ivToken.decimals();
        // when
        // then
        assertEq(decimals, 18);
    }

    function testShouldIvTokenDaiContain18Decimals() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        uint8 decimals = ivTokenDai.decimals();
        // when
        // then
        assertEq(decimals, 18);
    }

    function testShouldTransferOwnership() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address ownerBefore = ivTokenDai.owner();
        // when
        ivTokenDai.transferOwnership(_userOne);
        vm.prank(_userOne);
        ivTokenDai.confirmTransferOwnership();
        // then
        address ownerAfter = ivTokenDai.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _userOne);
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address ownerBefore = ivTokenDai.owner();
        // when
        vm.prank(_userOne);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        ivTokenDai.transferOwnership(_userOne);
        // then
        address ownerAfter = ivTokenDai.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address ownerBefore = ivTokenDai.owner();
        // when
        ivTokenDai.transferOwnership(_userOne);
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked("IPOR_007"));
        ivTokenDai.confirmTransferOwnership();
        // then
        address ownerAfter = ivTokenDai.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address ownerBefore = ivTokenDai.owner();
        ivTokenDai.transferOwnership(_userOne);
        vm.prank(_userOne);
        ivTokenDai.confirmTransferOwnership();
        // when
        vm.prank(_userOne);
        vm.expectRevert(abi.encodePacked("IPOR_007"));
        ivTokenDai.confirmTransferOwnership();
        // then
        address ownerAfter = ivTokenDai.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _userOne);
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address ownerBefore = ivTokenDai.owner();
        ivTokenDai.transferOwnership(_userOne);
        vm.prank(_userOne);
        ivTokenDai.confirmTransferOwnership();
        // when
        vm.prank(_admin);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        ivTokenDai.transferOwnership(_userOne);
        // then
        address ownerAfter = ivTokenDai.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _userOne);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        ivTokenDai.transferOwnership(_userOne);
        // when
        ivTokenDai.transferOwnership(_userTwo);
        // then
        address actualOwner = ivTokenDai.owner();
        assertEq(actualOwner, _admin);
    }

    function testShouldContainCorrectUnderlyingTokenAddress() public {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        address expectedUnderlyingTokenAddress = address(_mockTestnetTokenDai);
        // when
        address actualUnderlyingTokenAddress = ivTokenDai.getAsset();
        // then
        assertEq(actualUnderlyingTokenAddress, expectedUnderlyingTokenAddress);
    }

    function testShouldNotSendEthToIvTokenDai() public payable {
        // given
        IvToken ivTokenDai = new IvToken("IV DAI", "ivDAI", address(_mockTestnetTokenDai));
        // when
        // then
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        address(ivTokenDai).call{value: msg.value}("");
    }
}
