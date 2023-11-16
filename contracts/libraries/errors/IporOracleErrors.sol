// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library IporOracleErrors {
    // 200-299- iporOracle
    /// @notice Asset address not supported
    //@dev Address is not supported when lastUpdateTimestamp == 0.
    //When lastUpdateTimestamp is equal 0, then we assume that asset is not supported.
    string public constant ASSET_NOT_SUPPORTED = "IPOR_200";

    /// @notice Cannot add new asset to asset list, because it's already added
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_201";

    /// @notice The caller must be the IporOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_202";

    /// @notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = "IPOR_203";

    /// @notice Address is not a valid oracle address
    string public constant INVALID_ORACLE_ADDRESS = "IPOR_204";

    /// @notice wrong new index timestamp
    string public constant WRONG_INDEX_TIMESTAMP = "IPOR_205";

    /// @notice Emitted when an error occurs during the update of the IPOR index for a specific asset.
    /// @dev This error is typically emitted from methods responsible for updating the IPOR index values.
    /// @param asset The address of the asset (underlying/stablecoin) for which the index update was attempted.
    /// @param errorCode A string representing the error code associated with the failure of the update.
    /// @param methodName The name of the method where the error occurred during the index update process.
    error UpdateIndex(address asset, string errorCode, string methodName);
}
