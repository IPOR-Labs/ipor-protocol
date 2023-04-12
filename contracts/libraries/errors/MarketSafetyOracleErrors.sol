// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library MarketSafetyOracleErrors {
    // 700-799- market safety oracle
    //@notice Asset address not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_700";

    //@notice Cannot add new asset to asset list, because already exists
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_701";

    //@notice The caller must be the MarketSafetyOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_702";
}
