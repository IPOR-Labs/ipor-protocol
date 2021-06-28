// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

contract IporAmmStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;
}

/**
 * @title Ipor AMM Storage initial version 1
 * @author IPOR Labs
 */
contract IporAmmV1Storage is IporAmmStorage {

    // @notice Map of available Liquidity Pools, key in this map are underlying asset symbol
    mapping(bytes32 => address) public pools;

    // @notice list of long positions for particular asset, where buyer want to pay fixed and receive floating
    //TODO: figure out better structure
    mapping(bytes32 => DataTypes.IporDerivative[]) public payFixedPositions;

    // @notice list of short positions for particular asset, where buyer want to pay floating and reveice fixed
    //TODO: figure out better structure
    mapping(bytes32 => DataTypes.IporDerivative[]) public recFixedPositions;

    // @notice next derivative id (long or short)
    uint256 public nextDerivativeId;

    // @notice Sum Of All Payouts
    uint256 public soap;

}