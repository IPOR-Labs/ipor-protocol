// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/security/PauseManager.sol";
import "../../contracts/vault/StanleyUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";

contract StanleyPauseManagerTest is Test {
    address private _owner;
    address private _user1;
    address private _user2;

    MockTestnetToken private usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
    IvToken private ivUsdc = new IvToken("IV USDC", "ivUSDC", address(usdc));

    function setUp() public {
        _owner = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
    }

    function testShouldNotPauseIfNoGuardianIsSet() public {
        // given
        Stanley stanley = createStanley();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        stanley.pause();
    }

    function testShouldNotPauseWhenCalledByNonGuardian() public {
        // given
        Stanley stanley = createStanley();
        vm.prank(_owner);
        stanley.addGuardian(_user1);

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        stanley.pause();
    }

    function testShouldPauseWhenCalledByGuardian() public {
        // given
        Stanley stanley = createStanley();
        assertFalse(stanley.paused());
        vm.prank(_owner);
        stanley.addGuardian(_user1);

        // when
        vm.startPrank(_user1);
        stanley.pause();

        // then
        assertTrue(stanley.paused());
    }

    function testShouldNotPauseWhenCalledByRemovedGuardian() public {
        // given
        Stanley stanley = createStanley();
        assertFalse(stanley.paused());
        vm.prank(_owner);
        stanley.addGuardian(_user1);

        // when
        vm.prank(_owner);
        stanley.removeGuardian(_user1);

        // then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        stanley.pause();
        assertFalse(stanley.paused());
    }

    function testShouldNotRemoveGuardianWhenCalledByNonOwner() public {
        // given
        Stanley stanley = createStanley();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        stanley.removeGuardian(_user1);
    }

    function testShouldNotAddGuardianWhenCalledByNonOwner() public {
        // given
        Stanley stanley = createStanley();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        stanley.addGuardian(_user1);
    }

    function testShouldUnpauseWhenCalledByOwner() public {
        // given
        Stanley stanley = createStanley();
        assertFalse(stanley.paused());
        vm.prank(_owner);
        stanley.addGuardian(_user1);
        vm.prank(_user1);
        stanley.pause();
        assertTrue(stanley.paused());

        // when
        vm.prank(_owner);
        stanley.unpause();

        // then
        assertFalse(stanley.paused());
    }

    function testShouldNotUnpauseWhenCalledByGuardian() public {
        // given
        Stanley stanley = createStanley();
        assertFalse(stanley.paused());
        vm.prank(_owner);
        stanley.addGuardian(_user1);
        vm.prank(_user1);
        stanley.pause();
        assertTrue(stanley.paused());

        // when
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        stanley.unpause();

        // then
        assertTrue(stanley.paused());
    }

    function testShouldOwnerCannotPauseWhenNotGuardian() public {
        // given
        Stanley stanley = createStanley();
        assertFalse(stanley.paused());

        // when & then
        vm.startPrank(_owner);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        stanley.pause();
        assertFalse(stanley.paused());
    }

    function testShouldGuardianCannotAddGuardian() public {
        // given
        Stanley stanley = createStanley();
        vm.prank(_owner);
        stanley.addGuardian(_user1);

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        stanley.addGuardian(_user2);
    }

    function testShouldGuardianCannotRemoveGuardian() public {
        // given
        Stanley stanley = createStanley();
        vm.startPrank(_owner);
        stanley.addGuardian(_user1);
        stanley.addGuardian(_user2);
        vm.stopPrank();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        stanley.removeGuardian(_user2);
    }

    function createStrategy() internal returns (MockTestnetStrategy) {
        MockTestnetStrategy strategy = new MockTestnetStrategy();
        return
        MockTestnetStrategy(
            address(
                new ERC1967Proxy(
                    address(strategy),
                    abi.encodeWithSignature("initialize(address,address)", address(usdc), address(ivUsdc))
                )
            )
        );
    }

    function createStanley() internal returns (Stanley) {
        vm.startPrank(_owner);
        MockTestnetStrategy strategy = createStrategy();
        StanleyUsdc implementation = new StanleyUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(usdc),
                address(ivUsdc),
                address(strategy),
                address(strategy)
            )
        );
        vm.stopPrank();
        return Stanley(address(proxy));
    }

    event GuardianAdded(address indexed guardian);

    event GuardianRemoved(address indexed guardian);
}
