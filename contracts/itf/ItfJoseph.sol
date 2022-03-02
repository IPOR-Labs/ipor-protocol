// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../libraries/Constants.sol";
import "../tokenization/Joseph.sol";

contract ItfJoseph is Joseph {
    
    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for minting ipToken
    function itfProvideLiquidity(uint256 liquidityAmount, uint256 timestamp)
        external
    {
        _provideLiquidity(liquidityAmount, _decimals, timestamp);
    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for burning ipToken
    function itfRedeem(uint256 ipTokenVolume, uint256 timestamp) external {
        _redeem(ipTokenVolume, timestamp);
    }

}
