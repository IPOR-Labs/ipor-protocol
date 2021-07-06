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
    mapping(string => address) public tokens;

    // @notice total derivative balances for every asset
    mapping(string => uint256) public derivativesTotalBalances;

    //@notice Opening Fee total balances for every asset;
    mapping(string => uint256) public openingFeeTotalBalances;

    //@notice Liquidation Deposit total balances for every asset
    mapping(string => uint256) public liquidationDepositFeeTotalBalances;

    //@notice IPOR Publication Fee total balances for every asset
    mapping(string => uint256) public iporPublicationFeeTotalBalances;

    mapping(string => Balance) public balances;

    struct Balance {
        uint256 derivative;
        uint256 openingFee;
        uint256 liquidationDepositFee;
        uint256 iporPublicationFee;
    }

    // @notice list of long positions for particular asset, where buyer want to pay fixed and receive floating
    // first key is an address of token, second key is an address of trader
    DataTypes.IporDerivative[] public derivatives;

    // @notice next derivative id (long or short)
    uint256 public nextDerivativeId;

    // @notice Sum Of All Payouts
    uint256 public soap;

}