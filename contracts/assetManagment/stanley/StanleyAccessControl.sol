// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../../IporErrors.sol";

abstract contract StanleyAccessControl is AccessControl {
    bytes32 internal constant _ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant _GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 internal constant _DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 internal constant _WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 internal constant _CLAIM_ROLE = keccak256("CLAIM_ROLE");

    function _init() internal {
        _setupRole(_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_GOVERNANCE_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_DEPOSIT_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_WITHDRAW_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_CLAIM_ROLE, _ADMIN_ROLE);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role != _ADMIN_ROLE) {
            super.revokeRole(role, account);
        } else {
            require(
                _msgSender() != account,
                IporErrors.CONFIG_REVOKE_ADMIN_ROLE_NOT_ALLOWED
            );
            super.revokeRole(role, account);
        }
    }
}
