// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

/// @title Struct used across Liquidity Mining.
library PowerTokenTypes {
    struct PwTokenCooldown {
        // @dev The timestamp when the account can redeem Power Tokens
        uint256 endTimestamp;
        // @dev The amount of Power Tokens which can be redeemed without fee when the cooldown reaches `endTimestamp`
        uint256 pwTokenAmount;
    }

    struct UpdateStakedToken {
        address beneficiary;
        uint256 stakedTokenAmount;
    }
}
