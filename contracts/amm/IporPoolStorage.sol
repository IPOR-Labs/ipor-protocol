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

    //@notice Address of Smart Contract in ERC20 Token Standard. Smart Contract operate on underlying asset which is ERC20 token.
    address public token;

    //@notice Address of Smart Contract in ERC20 Token Standard. Smart Contract operate on IPOR token which is ERC20 token and refer to underlying asset.
    address public ipToken;

    //@notice Total pool token balance
    uint256 public poolTokenBalance;

    //@notice Total pool ipToken (IPOR Token) balance
    uint256 public poolIpTokenBalance;

    //@notice Pay fixed receive floating (long) token balance
    uint256 public payFixTokenBalance;

    //@notice Pay fixed receive floating (short) ipToken balance
    uint256 public payFixIpTokenBalance;

    //@notice Receive fixed, pay floating (long) token balance
    uint256 public recFixTokenBalance;

    //@notice Receive fixed, pay floating (short) ipToken balance
    uint256 public recFixIpTokenBalance;

    //@notice Pay fixed receive floating token pool reserved
    uint256 public payFixTokenPoolReserved;

    //@notice Pay fixed receive floating ipToken pool reserved
    uint256 public payFixIpTokenPoolReserved;

    //@notice Receive fixed, pay floating token pool reserved
    uint256 public recFixTokenPoolReserved;

    //@notice Receive fixed, pay floating  ipToken pool reserved
    uint256 public recFixIpTokenPoolReserved;


}