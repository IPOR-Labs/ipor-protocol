// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library IporOracleErrors {
    // 200-299- iporOracle
    //@notice Asset address not supported
    //@dev Address is not supported when quasiIbtPrice < Constants.WAD_YEAR_IN_SECONDS.
    //When quasiIbtPrice is lower than WAD_YEAR_IN_SECONDS (ibtPrice lower than 1), then we assume that asset is not supported.
    string public constant ASSET_NOT_SUPPORTED = "IPOR_200";

    //@notice Cannot add new asset to asset list, because already exists
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_201";

    //@notice The caller must be the IporOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_202";

    //@notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = "IPOR_203";

    //@notice Address of algorithm used to calculate IPOR Index is not set
    string public constant IPOR_ALGORITHM_ADDRESS_NOT_SET = "IPOR_204";
}
