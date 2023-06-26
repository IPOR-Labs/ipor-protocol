// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "test/TestCommons.sol";
import "test/mocks/tokens/MockTestnetToken.sol";
import "contracts/amm/AmmStorage.sol";

contract AmmPoolsServiceOnlyRebalanceTest is Test, TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _cfg.iporRiskManagementOracleUpdater = address(this);
    }

    function testShouldNotRebalanceWhenNotAppointedSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));
    }

    function testShouldAddUserToAppointedRebalanceSender() public {
        // given
        address user = _getUserAddress(1);
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        bool isAppointedBefore = _iporProtocol.ammGovernanceLens.isAppointedToRebalanceInAmm(
            address(_iporProtocol.asset),
            user
        );

        // when
        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), user);

        // then
        bool isAppointedAfter = _iporProtocol.ammGovernanceLens.isAppointedToRebalanceInAmm(
            address(_iporProtocol.asset),
            user
        );
        assertFalse(isAppointedBefore);
        assertTrue(isAppointedAfter);
    }

    function testShouldRemoveUserFromAppointedRebalanceSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address user = _getUserAddress(1);

        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), user);
        bool isAppointedBefore = _iporProtocol.ammGovernanceLens.isAppointedToRebalanceInAmm(
            address(_iporProtocol.asset),
            user
        );

        // when
        _iporProtocol.ammGovernanceService.removeAppointedToRebalanceInAmm(address(_iporProtocol.asset), user);

        // then
        bool isAppointedAfter = _iporProtocol.ammGovernanceLens.isAppointedToRebalanceInAmm(
            address(_iporProtocol.asset),
            user
        );
        assertTrue(isAppointedBefore);
        assertFalse(isAppointedAfter);
    }

    function testShouldRebalanceWhenAppointedSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), address(this));

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.ASSET_MANAGEMENT_BALANCE_IS_EMPTY));
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));
    }
}
