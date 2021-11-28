// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessControlRevoke is AccessControl {
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant ROLES_INFO_ROLE = keccak256("ROLES_INFO_ROLE");
    mapping(bytes32 => address[]) private roleMembers;
    mapping(address => bytes32[]) private userRoles;

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role != ADMIN_ROLE) {
            super.revokeRole(role, account);
            _revolke(role, account);
        } else {
            require(
                _msgSender() != account,
                "ADMIN_ROLE can be revoked only by different user with ADMIN_ROLE"
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
        address[] memory usersWithRole = new address[](roleMembers[role].length -1); 
        for (uint256 index = 0; index < usersWithRole.length; index++) {
            if (account == roleMembers[role][index]) {
                i++;
            }
            usersWithRole[index] = roleMembers[role][index+i];
        }
        roleMembers[role] = usersWithRole;
    }

    function _revolkeFromMemberRoles(bytes32 role, address account) private {
        uint8 i = 0;
        bytes32[] memory rolesWithUser = new bytes32[](userRoles[account].length -1); 
        for (uint256 index = 0; index < rolesWithUser.length; index++) {
            if (role == userRoles[account][index]) {
                i++;
            }
            rolesWithUser[index] = userRoles[account][index+i];
        }
        userRoles[account] = rolesWithUser;
    }


    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (!hasRole(role, account)) {
            super.grantRole(role, account);
            userRoles[account].push(role);
            roleMembers[role].push(account);
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual override{
        if (!hasRole(role, account)) {
            super._setupRole(role, account);
            userRoles[account].push(role);
            roleMembers[role].push(account);
        }
    }

    //TODO: Pete write tests for this
    function getUserRoles(address account)
        external
        view
        onlyRole(ROLES_INFO_ROLE)
        returns (bytes32[] memory)
    {
        return userRoles[account];
    }

    //TODO: Pete write tests for this
    function getRoleMembers(bytes32 role)
        external
        view
        onlyRole(ROLES_INFO_ROLE)
        returns (address[] memory)
    {
        return roleMembers[role];
    }
}
