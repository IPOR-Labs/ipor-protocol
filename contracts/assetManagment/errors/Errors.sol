// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

// TODO: move to IP-Errors
library Errors {
    //@notice ADMIN_ROLE can be revoked only by different user with ADMIN_ROLE
    string public constant CONFIG_REVOKE_ADMIN_ROLE_NOT_ALLOWED =
        "IPOR_ASSET_MANAGMENT_01";
    string public constant IPOR_VAULT_TOKEN_MINT_AMOUNT_TOO_LOW =
        "IPOR_ASSET_MANAGMENT_02";
    string public constant IPOR_VAULT_TOKEN_BURN_AMOUNT_TOO_LOW =
        "IPOR_ASSET_MANAGMENT_03";
    string public constant UNDERLYINGTOKEN_IS_NOT_COMPATIBLY =
        "IPOR_ASSET_MANAGMENT_04";
    string public constant ZERO_ADDRESS = "IPOR_ASSET_MANAGMENT_05";
    string public constant UINT_SHOULD_BE_GRATER_THEN_ZERO =
        "IPOR_ASSET_MANAGMENT_06";
    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER =
        "IPOR_ASSET_MANAGMENT_07";
    // only vault can have access to function
    string public constant ONLY_VAULT = "IPOR_ASSET_MANAGMENT_08";
}
