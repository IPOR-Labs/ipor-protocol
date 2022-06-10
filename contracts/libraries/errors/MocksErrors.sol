// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library MocksErrors {
    // 600-699 - general codes

    /// @notice User can claim only once every 24h
    string public constant CAN_CLAIM_ONCE_EVERY_24H = "IPOR_600";
}
