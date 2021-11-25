// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessControlRevoke is AccessControl {
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role != ADMIN_ROLE) {
            super.revokeRole(role, account);
        } else {
            require(
                _msgSender() != account,
                "ADMIN_ROLE can be revoked only by different user with ADMIN_ROLE"
            );
            super.revokeRole(role, account);
        }
    }
}
