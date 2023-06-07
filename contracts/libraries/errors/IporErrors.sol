// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    //@notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    //only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @dev Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";
    string public constant CALLER_NOT_OWNER = "IPOR_014";
    string public constant METHOD_PAUSED = "IPOR_015";
    string public constant REENTRANCY = "IPOR_016";
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

}
