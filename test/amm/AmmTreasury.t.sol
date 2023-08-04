// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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
        _cfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldPauseSCWhenSenderIsPauseGuardian() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammTreasury.addPauseGuardian(_admin);
        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        _iporProtocol.ammTreasury.pause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSCSpecificMethods() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammTreasury.addPauseGuardian(_admin);
        _iporProtocol.ammTreasury.pause();

        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        vm.startPrank(_getUserAddress(1));
        _iporProtocol.ammTreasury.getVersion();
        _iporProtocol.ammTreasury.getConfiguration();
        _iporProtocol.ammTreasury.isPauseGuardian(_getUserAddress(1));
        vm.stopPrank();

        // admin
        _iporProtocol.ammTreasury.addPauseGuardian(_getUserAddress(1));
        _iporProtocol.ammTreasury.removePauseGuardian(_getUserAddress(1));
        _iporProtocol.ammTreasury.grandMaxAllowanceForSpender(_getUserAddress(1));
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
        _iporProtocol.ammTreasury.addPauseGuardian(_admin);
        _iporProtocol.ammTreasury.pause();
        _iporProtocol.ammTreasury.removePauseGuardian(_admin);

        bool pausedBefore = _iporProtocol.ammTreasury.paused();

        // when
        _iporProtocol.ammTreasury.unpause();

        // then
        bool pausedAfter = _iporProtocol.ammTreasury.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammTreasury.addPauseGuardian(_admin);
        _iporProtocol.ammTreasury.pause();
        _iporProtocol.ammTreasury.removePauseGuardian(_admin);

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