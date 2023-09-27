// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library AssetManagementErrors {
    // 500-599-assetManagement

    /// @notice asset mismatch
    string public constant ASSET_MISMATCH = "IPOR_500";

    // @notice caller is not asset management contract
    string public constant CALLER_NOT_ASSET_MANAGEMENT = "IPOR_501";

    /// @notice treasury address is incorrect
    string public constant INCORRECT_TREASURY_ADDRESS = "IPOR_502";

    /// @notice iv token value which should be minted is too low
    string public constant IV_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_503";

    /// @notice iv token value which should be burned is too low
    string public constant IV_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_504";

    /// @notice only Treasury Manager can access the function
    string public constant CALLER_NOT_TREASURY_MANAGER = "IPOR_505";

    /// @notice  problem with redeem shared token
    string public constant SHARED_TOKEN_REDEEM_ERROR = "IPOR_506";

    /// @dev Error appears if deposit every strategy failed
    string public constant DEPOSIT_TO_STRATEGY_FAILED = "IPOR_507";

    /// @dev Error appears when deposited amount returned from strategy is not higher than 0 and lower than amount sent to strategy
    string public constant STRATEGY_INCORRECT_DEPOSITED_AMOUNT = "IPOR_508";
}
