// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/AmmTreasury.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/interfaces/types/AmmStorageTypes.sol";

contract AmmTreasuryTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
    }

    function testShouldPauseSCWhenSenderIsPauseGuardian() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporProtocol.ammTreasury.addPauseGuardians(pauseGuardians);
        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        uint256 allowanceBefore = IERC20Upgradeable(address(_iporProtocol.asset)).allowance(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.router)
        );

        // when
        _iporProtocol.ammTreasury.pause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        uint256 allowanceAfter = IERC20Upgradeable(address(_iporProtocol.asset)).allowance(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.router)
        );

        assertGt(allowanceBefore, 0);
        assertEq(allowanceAfter, 0);

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSCSpecificMethods() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporProtocol.ammTreasury.addPauseGuardians(pauseGuardians);
        _iporProtocol.ammTreasury.pause();

        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        vm.startPrank(_getUserAddress(1));
        _iporProtocol.ammTreasury.getVersion();
        _iporProtocol.ammTreasury.getConfiguration();
        _iporProtocol.ammTreasury.isPauseGuardian(_getUserAddress(1));
        vm.stopPrank();

        // admin
        pauseGuardians[0] = _getUserAddress(1);
        _iporProtocol.ammTreasury.addPauseGuardians(pauseGuardians);
        _iporProtocol.ammTreasury.removePauseGuardians(pauseGuardians);
        _iporProtocol.ammTreasury.grantMaxAllowanceForSpender(_getUserAddress(1));
        _iporProtocol.ammTreasury.revokeAllowanceForSpender(_getUserAddress(1));

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnPauseGuardian() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        _iporProtocol.ammTreasury.pause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporProtocol.ammTreasury.addPauseGuardians(pauseGuardians);
        _iporProtocol.ammTreasury.pause();
        _iporProtocol.ammTreasury.removePauseGuardians(pauseGuardians);

        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        uint256 allowanceBefore = IERC20Upgradeable(address(_iporProtocol.asset)).allowance(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.router)
        );

        // when
        _iporProtocol.ammTreasury.unpause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        uint256 allowanceAfter = IERC20Upgradeable(address(_iporProtocol.asset)).allowance(
            address(_iporProtocol.ammTreasury),
            address(_iporProtocol.router)
        );

        assertEq(allowanceBefore, 0);
        assertEq(allowanceAfter, Constants.MAX_VALUE);

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        _iporProtocol.ammTreasury.addPauseGuardians(pauseGuardians);
        _iporProtocol.ammTreasury.pause();
        _iporProtocol.ammTreasury.removePauseGuardians(pauseGuardians);

        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporProtocol.ammTreasury.unpause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }
}
