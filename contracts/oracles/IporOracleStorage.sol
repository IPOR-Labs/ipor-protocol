// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

contract IporOracleStorage {

    /**
    * @notice Administrator for this contract
    */
    address public admin;

}

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
contract IporOracleV1Storage is IporOracleStorage {

    struct IporIndex {
        string ticker;
        uint256 value;
        uint256 interestBearingToken;
        uint256 date;
    }

    /// @notice list of IPOR indexes for particular assets
    mapping(bytes32 => IporIndex) public indexes;

    /// @notice list of tickers used in indexes mapping
    bytes32[] public tickers;

    /// @notice list of addresses which has rights to modify indexes mapping
    address[] public updaters;
}