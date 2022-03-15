// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

// 000-199 - general codes
// 200-299- warren
// 300-399-milton
// 400-499-joseph
// 500-599-stanley
library IporErrors {
    // 000-199 - general codes

    //@notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    //@notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    //@notice Asset has too low decimals
    string public constant ASSET_DECIMALS_TOO_LOW = "IPOR_002";

    //@notice Trader doesnt have enought tokens to execute transaction
    string public constant ASSET_BALANCE_TOO_LOW = "IPOR_003";

    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    //@notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    //only milton can have access to function
    string public constant CALLER_NOT_MILTON = "IPOR_008";

    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";
}
