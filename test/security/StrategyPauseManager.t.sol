// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../contracts/security/PauseManager.sol";
import "../../contracts/vault/StanleyUsdc.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";

contract StrategyPauseManagerTest is Test {
    address private _owner;
    address private _user1;
    address private _user2;

    MockTestnetToken private usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
    IvToken ivUsdc = new IvToken("IV USDC", "ivUSDC", address(usdc));

    function setUp() public {
        _owner = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
    }

    function testShouldEmitPauseGuardianAddedEvent() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_owner);
        vm.expectEmit(true, true, true, true);
        emit PauseGuardianAdded(_user1);
        strategy.addPauseGuardian(_user1);
    }

    function testShouldEmitPauseGuardianRemovedEvent() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.startPrank(_owner);
        strategy.addPauseGuardian(_user1);

        // when & then
        vm.expectEmit(true, true, true, true);
        emit PauseGuardianRemoved(_user1);
        strategy.removePauseGuardian(_user1);
    }

    function testShouldNotPauseIfNoGuardianIsSet() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
    }

    function testShouldNotPauseWhenCalledByNonGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardian(_user1);

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        strategy.pause();
    }

    function testShouldPauseWhenCalledByGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardian(_user1);

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
        strategy.addPauseGuardian(_user1);

        // when
        vm.prank(_owner);
        strategy.removePauseGuardian(_user1);

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
        strategy.removePauseGuardian(_user1);
    }

    function testShouldNotAddPauseGuardianWhenCalledByNonOwner() public {
        // given
        StrategyCore strategy = createStrategy();

        // when & then
        vm.startPrank(_user2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.addPauseGuardian(_user1);
    }

    function testShouldUnpauseWhenCalledByOwner() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.prank(_owner);
        strategy.addPauseGuardian(_user1);
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
        strategy.addPauseGuardian(_user1);
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
        strategy.addPauseGuardian(_user1);
        vm.stopPrank();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.addPauseGuardian(_user2);
    }

    function testShouldGuardianCannotRemovePauseGuardian() public {
        // given
        StrategyCore strategy = createStrategy();
        vm.startPrank(_owner);
        strategy.addPauseGuardian(_user1);
        strategy.addPauseGuardian(_user2);
        vm.stopPrank();

        // when & then
        vm.startPrank(_user1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        strategy.removePauseGuardian(_user2);
    }

    function createStrategy() internal returns (StrategyCore) {
        StrategyCore strategy = new StrategyCompoundUsdc();
        vm.startPrank(_owner);
        StrategyCore proxy = StrategyCore(
            address(
                new ERC1967Proxy(
                    address(strategy),
                    abi.encodeWithSignature(
                        "initialize(address,address,address,address)",
                        address(usdc),
                        address(ivUsdc),
                        address(this),
                        address(this)
                    )
                )
            )
        );
        vm.stopPrank();
        return proxy;
    }

    event PauseGuardianAdded(address indexed guardian);

    event PauseGuardianRemoved(address indexed guardian);
}
