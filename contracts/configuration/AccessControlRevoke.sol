// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IporErrors} from "../IporErrors.sol";

abstract contract AccessControlRevoke is AccessControl {
    bytes32 internal constant _ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant _ROLES_INFO_ROLE = keccak256("ROLES_INFO_ROLE");
    bytes32 internal constant _ROLES_INFO_ADMIN_ROLE =
        keccak256("ROLES_INFO_ADMIN_ROLE");
    mapping(bytes32 => address[]) private _roleMembers;
    mapping(address => bytes32[]) private _userRoles;

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role != _ADMIN_ROLE) {
            super.revokeRole(role, account);
            _revolke(role, account);
        } else {
            require(
                _msgSender() != account,
                IporErrors.CONFIG_REVOKE_ADMIN_ROLE_NOT_ALLOWED
            );
            super.revokeRole(role, account);
            _revolke(role, account);
        }
    }

    function _revolke(bytes32 role, address account) private {
        _revolkeFromRoleMembers(role, account);
        _revolkeFromMemberRoles(role, account);
    }

    function _revolkeFromRoleMembers(bytes32 role, address account) private {
        uint8 i = 0;
        address[] memory tempMembers = _roleMembers[role];
        address[] memory usersWithRole = new address[](tempMembers.length - 1);
        for (uint256 index = 0; index < usersWithRole.length; index++) {
            if (account == tempMembers[index]) {
                i++;
            }
            usersWithRole[index] = tempMembers[index + i];
        }
        _roleMembers[role] = usersWithRole;
    }

    function _revolkeFromMemberRoles(bytes32 role, address account) private {
        uint8 i = 0;
        bytes32[] memory tempRoles = _userRoles[account];
        bytes32[] memory rolesWithUser = new bytes32[](tempRoles.length - 1);
        for (uint256 index = 0; index < rolesWithUser.length; index++) {
            if (role == tempRoles[index]) {
                i++;
            }
            rolesWithUser[index] = tempRoles[index + i];
        }
        _userRoles[account] = rolesWithUser;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (!hasRole(role, account)) {
            super.grantRole(role, account);
            _userRoles[account].push(role);
            _roleMembers[role].push(account);
        }
    }

    function _setupRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        if (!hasRole(role, account)) {
            super._setupRole(role, account);
            _userRoles[account].push(role);
            _roleMembers[role].push(account);
        }
    }

    //TODO: Pete write tests for this
    function getUserRoles(address account)
        external
        view
        onlyRole(_ROLES_INFO_ROLE)
        returns (bytes32[] memory)
    {
        return _userRoles[account];
    }

    //TODO: Pete write tests for this
    function getRoleMembers(bytes32 role)
        external
        view
        onlyRole(_ROLES_INFO_ROLE)
        returns (address[] memory)
    {
        return _roleMembers[role];
    }
}
