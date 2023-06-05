// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library AssetManagementErrors {
    // 500-599-assetManagement
    string public constant ASSET_MISMATCH = "IPOR_500";

    // only assetManagement can have access to function
    string public constant CALLER_NOT_ASSET_MANAGEMENT = "IPOR_501";

    string public constant INCORRECT_TREASURY_ADDRESS = "IPOR_502";

    //@notice amount should be > 0
    string public constant IV_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_503";

    //@notice amount should be > 0
    string public constant IV_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_504";

    // only Treasury Manager can have access to function
    string public constant CALLER_NOT_TREASURY_MANAGER = "IPOR_505";

    // problem with redeem shared token
    string public constant SHARED_TOKEN_REDEEM_ERROR = "IPOR_506";

}
