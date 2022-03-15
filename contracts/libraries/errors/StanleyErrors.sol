// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

// 000-199 - general codes
// 200-299- warren
// 300-399-milton
// 400-499-joseph
// 500-599-stanley
library StanleyErrors {
    // 500-599-stanley
    string public constant ASSET_MISMATCH = "IPOR_500";

    // only stanley can have access to function
    string public constant CALLER_NOT_STANLEY = "IPOR_501";

    string public constant INCORRECT_TREASURY_ADDRESS = "IPOR_502";

    //@notice amount should be > 0
    string public constant IV_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_503";

    //@notice amount should be > 0
    string public constant IV_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_504";

    // only Treasury Manager can have access to function
    string public constant CALLER_NOT_TREASURY_MANAGER = "IPOR_505";
}
