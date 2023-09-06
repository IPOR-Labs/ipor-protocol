// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/vault/AssetManagementUsdc.sol";

import "../mocks/assetManagement/MockTestnetStrategy.sol";
import "forge-std/Test.sol";
import "../mocks/tokens/MockTestnetToken.sol";

contract AssetManagementPauseManagerTest is Test {
//    address private _owner;
//    address private _user1;
//    address private _user2;
//
//    MockTestnetToken private usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
//    IvToken private ivUsdc = new IvToken("IV USDC", "ivUSDC", address(usdc));
//
//    function setUp() public {
//        _owner = vm.rememberKey(1);
//        _user1 = vm.rememberKey(2);
//        _user2 = vm.rememberKey(3);
//    }
//
//    function testShouldEmitPauseGuardianAddedEvent() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//
//        // when & then
//        vm.startPrank(_owner);
//        vm.expectEmit(true, true, true, true);
//        emit PauseGuardianAdded(_user1);
//        assetManagement.addPauseGuardian(_user1);
//    }
//
//    function testShouldEmitPauseGuardianRemovedEvent() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        vm.startPrank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//
//        // when & then
//        vm.expectEmit(true, true, true, true);
//        emit PauseGuardianRemoved(_user1);
//        assetManagement.removePauseGuardian(_user1);
//    }
//
//    function testShouldNotPauseIfNoPauseGuardianIsSet() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//
//        // when & then
//        vm.startPrank(_user1);
//        vm.expectRevert(abi.encodePacked("IPOR_011"));
//        assetManagement.pause();
//    }
//
//    function testShouldNotPauseWhenCalledByNonPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//
//        // when & then
//        vm.startPrank(_user2);
//        vm.expectRevert(abi.encodePacked("IPOR_011"));
//        assetManagement.pause();
//    }
//
//    function testShouldPauseWhenCalledByPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        assertFalse(assetManagement.paused());
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//
//        // when
//        vm.startPrank(_user1);
//        assetManagement.pause();
//
//        // then
//        assertTrue(assetManagement.paused());
//    }
//
//    function testShouldNotPauseWhenCalledByRemovedPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        assertFalse(assetManagement.paused());
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//
//        // when
//        vm.prank(_owner);
//        assetManagement.removePauseGuardian(_user1);
//
//        // then
//        vm.startPrank(_user1);
//        vm.expectRevert(abi.encodePacked("IPOR_011"));
//        assetManagement.pause();
//        assertFalse(assetManagement.paused());
//    }
//
//    function testShouldNotRemovePauseGuardianWhenCalledByNonOwner() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//
//        // when & then
//        vm.startPrank(_user2);
//        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
//        assetManagement.removePauseGuardian(_user1);
//    }
//
//    function testShouldNotAddPauseGuardianWhenCalledByNonOwner() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//
//        // when & then
//        vm.startPrank(_user2);
//        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
//        assetManagement.addPauseGuardian(_user1);
//    }
//
//    function testShouldUnpauseWhenCalledByOwner() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        assertFalse(assetManagement.paused());
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//        vm.prank(_user1);
//        assetManagement.pause();
//        assertTrue(assetManagement.paused());
//
//        // when
//        vm.prank(_owner);
//        assetManagement.unpause();
//
//        // then
//        assertFalse(assetManagement.paused());
//    }
//
//    function testShouldNotUnpauseWhenCalledByPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        assertFalse(assetManagement.paused());
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//        vm.prank(_user1);
//        assetManagement.pause();
//        assertTrue(assetManagement.paused());
//
//        // when
//        vm.startPrank(_user1);
//        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
//        assetManagement.unpause();
//
//        // then
//        assertTrue(assetManagement.paused());
//    }
//
//    function testShouldOwnerCannotPauseWhenNotPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        assertFalse(assetManagement.paused());
//
//        // when & then
//        vm.startPrank(_owner);
//        vm.expectRevert(abi.encodePacked("IPOR_011"));
//        assetManagement.pause();
//        assertFalse(assetManagement.paused());
//    }
//
//    function testShouldPauseGuardianCannotAddPauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        vm.prank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//
//        // when & then
//        vm.startPrank(_user1);
//        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
//        assetManagement.addPauseGuardian(_user2);
//    }
//
//    function testShouldPauseGuardianCannotRemovePauseGuardian() public {
//        // given
//        AssetManagement.sol assetManagement = createAssetManagement();
//        vm.startPrank(_owner);
//        assetManagement.addPauseGuardian(_user1);
//        assetManagement.addPauseGuardian(_user2);
//        vm.stopPrank();
//
//        // when & then
//        vm.startPrank(_user1);
//        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
//        assetManagement.removePauseGuardian(_user2);
//    }
//
//    function createStrategy() internal returns (MockTestnetStrategy) {
//        MockTestnetStrategy strategy = new MockTestnetStrategy();
//        return
//            MockTestnetStrategy(
//                address(
//                    new ERC1967Proxy(
//                        address(strategy),
//                        abi.encodeWithSignature("initialize(address,address)", address(usdc), address(ivUsdc))
//                    )
//                )
//            );
//    }
//
//    function createAssetManagement() internal returns (AssetManagement.sol) {
//        vm.startPrank(_owner);
//        MockTestnetStrategy strategy = createStrategy();
//        AssetManagementUsdc implementation = new AssetManagementUsdc();
//        ERC1967Proxy proxy = new ERC1967Proxy(
//            address(implementation),
//            abi.encodeWithSignature(
//                "initialize(address,address,address,address)",
//                address(usdc),
//                address(ivUsdc),
//                address(strategy),
//                address(strategy)
//            )
//        );
//        vm.stopPrank();
//        return AssetManagement(address(proxy));
//    }
//
//    event PauseGuardianAdded(address indexed guardian);
//
//    event PauseGuardianRemoved(address indexed guardian);
}
