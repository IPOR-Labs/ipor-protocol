// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/vault/strategies/StrategyCore.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "forge-std/Test.sol";

contract StrategyPauseManagerTest is Test {
    address private _owner;
    address private _user1;
    address private _user2;
    address[] private _pauseGuardians;

    MockTestnetToken private usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));

    function setUp() public {
        _owner = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
        _pauseGuardians = new address[](1);
        _pauseGuardians[0] = _user1;
    }

    function testShouldEmitPauseGuardianAddedEvent() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_owner);
        vm.expectEmit(true, true, true, true);
        emit PauseGuardiansAdded(_pauseGuardians);
        strategy.addPauseGuardians(_pauseGuardians);
    }

    function testShouldEmitPauseGuardianRemovedEvent() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.startPrank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);

        // when & then
        vm.expectEmit(true, true, true, true);
        emit PauseGuardiansRemoved(_pauseGuardians);
        strategy.removePauseGuardians(_pauseGuardians);
    }

    function testShouldNotPauseIfNoGuardianIsSet() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
    }

    function testShouldNotPauseWhenCalledByNonGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
    }

    function testShouldPauseWhenCalledByGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);

        // when
        vm.startPrank(_user1);
        strategy.pause();

        // then
        assertTrue(strategy.paused());
    }

    function testShouldNotPauseWhenCalledByRemovedGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);

        // when
        vm.prank(_owner);
        strategy.removePauseGuardians(_pauseGuardians);

        // then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
        assertFalse(strategy.paused());
    }

    function testShouldNotRemovePauseGuardianWhenCalledByNonOwner() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.removePauseGuardians(_pauseGuardians);
    }

    function testShouldNotAddPauseGuardianWhenCalledByNonOwner() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.addPauseGuardians(_pauseGuardians);
    }

    function testShouldUnpauseWhenCalledByOwner() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);
        vm.prank(_user1);
        strategy.pause();

        // when
        vm.prank(_owner);
        strategy.unpause();

        // then
        assertFalse(strategy.paused());
    }

    function testShouldNotUnpauseWhenCalledByGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);
        vm.prank(_user1);
        strategy.pause();

        // when
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.unpause();

        // then
        assertTrue(strategy.paused());
    }

    function testShouldOwnerCannotPauseWhenNotGuardian() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_owner);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
        assertFalse(strategy.paused());
    }

    function testShouldGuardianCannotAddPauseGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.startPrank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);
        vm.stopPrank();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.addPauseGuardians(_pauseGuardians);
    }

    function testShouldGuardianCannotRemovePauseGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.startPrank(_owner);
        strategy.addPauseGuardians(_pauseGuardians);
        _pauseGuardians[0] = _user2;
        strategy.addPauseGuardians(_pauseGuardians);
        vm.stopPrank();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.removePauseGuardians(_pauseGuardians);
    }

    function createStrategy() internal returns (StrategyCore) {
        StrategyCore strategy = new StrategyCompound(
            address(usdc),
            6,
            address(this),
            address(this),
            7200,
            address(this),
            address(this)
        );
        vm.startPrank(_owner);
        StrategyCore proxy = StrategyCore(
            address(new ERC1967Proxy(address(strategy), abi.encodeWithSignature("initialize()")))
        );
        vm.stopPrank();
        return proxy;
    }

    event PauseGuardiansAdded(address[] indexed guardians);

    event PauseGuardiansRemoved(address[] indexed guardians);
}
