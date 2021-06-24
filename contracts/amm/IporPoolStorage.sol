// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

contract IporPoolStorage {

    /**
    * @notice Administrator for this contract
    */
    address public admin;
}


/**
 * @title Ipor Liquidity Pool Storage initial version 1
 * @author IPOR Labs
 */
contract IporPoolV1Storage is IporPoolStorage {

    //@notice Asset name
    string public ticker;

    //@notice Total pool balance
    uint256 public poolBalance;

    //@notice Long pool balance
    uint256 public longPoolBalance;

    //@notice Short pool balance
    uint256 public shortPoolBalance;

    //@notice Long pool reserved
    uint256 public longPoolReserved;

    //@notice Short pool reserved
    uint256 public shortPoolReserved;

}