// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../TestForkCommons.sol";

contract ForkStrategyAaveGovernanceTest is TestForkCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _user;

    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18560825);
        _user = vm.rememberKey(2);
    }

    function testShouldNotBeAbleToSetupTreasury() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        // when
        vm.expectRevert("IPOR_502");
        vm.prank(owner);
        strategy.setTreasury(address(0));
    }

    function testShouldNotBeAbleToSetupTreasuryWhenSenderIsNotTreasuryManager() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        // when
        vm.expectRevert("IPOR_505");
        vm.prank(_user);
        strategy.setTreasury(address(0));
    }

    function testShouldNotBeAbleToSetupTreasuryManager() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        //when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_user);
        strategy.setTreasuryManager(address(0));
    }

    function testShouldBeAbleToSetupTreasuryManager() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        //when
        vm.prank(owner);
        strategy.setTreasuryManager(_user);

        //then
        assertEq(_user, strategy.getTreasuryManager(), "treasuryManager");
    }

    function testShouldBeAbleToSetupTreasury() public {
        //given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        vm.prank(owner);
        strategy.setTreasuryManager(_user);

        //when
        vm.prank(_user);
        strategy.setTreasury(_user);

        //then
        assertEq(_user, strategy.getTreasury(), "treasuryManager");
    }

    function testShouldBeAbleToPauseContractWhenSenderIsPauseGuardian() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        address[] memory guardians = new address[](1);
        guardians[0] = _user;

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        // when
        vm.prank(_user);
        strategy.pause();

        // then
        assertTrue(strategy.paused());
    }

    function testShouldBeAbleToUnpauseContractWhenSenderIsOwner() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        address[] memory guardians = new address[](1);
        guardians[0] = _user;

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        vm.prank(_user);
        strategy.pause();

        assertTrue(strategy.paused());

        // when
        vm.prank(owner);
        strategy.unpause();

        // then
        assertFalse(strategy.paused());
    }

    function testShouldNotBeAbleToUnpauseContractWhenSenderIsNotOwner() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        address[] memory guardians = new address[](1);
        guardians[0] = _user;

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        vm.prank(_user);
        strategy.pause();

        assertTrue(strategy.paused());

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_user);
        strategy.unpause();
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        address[] memory guardians = new address[](1);
        guardians[0] = _user;

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        //when
        vm.prank(_user);
        strategy.pause();

        //then
        assertTrue(strategy.paused());

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        vm.prank(owner);
        strategy.removePauseGuardians(guardians);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        _init();
        _createNewStrategyAaveDai();

        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);

        address[] memory guardians = new address[](1);
        guardians[0] = _user;

        vm.prank(owner);
        strategy.addPauseGuardians(guardians);

        //when
        vm.prank(_user);
        strategy.pause();

        //then
        assertTrue(strategy.paused());

        vm.expectRevert("Pausable: paused");
        strategy.deposit(1000 * 1e18);

        vm.expectRevert("Pausable: paused");
        strategy.withdraw(1000 * 1e18);

        vm.expectRevert("Pausable: paused");
        strategy.beforeClaim();

        vm.expectRevert("Pausable: paused");
        strategy.doClaim();

        vm.expectRevert("Pausable: paused");
        strategy.setTreasuryManager(_user);

        vm.expectRevert("Pausable: paused");
        strategy.setTreasury(_user);

        vm.expectRevert("Pausable: paused");
        vm.prank(_user);
        strategy.pause();
    }
}
