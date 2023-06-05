// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library IporRiskManagementOracleErrors {
    // 700-799- risk management oracle
    //@notice Asset address not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_700";

    //@notice Cannot add new asset to asset list, because already exists
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_701";

    //@notice The caller must be the IporRiskManagementOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_702";
}
