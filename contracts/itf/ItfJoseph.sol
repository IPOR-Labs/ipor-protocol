// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IMiltonStorage.sol";
import "../amm/pool/Joseph.sol";

abstract contract ItfJoseph is Joseph {
    function itfCalculateExchangeRate(uint256 timestamp) external view returns (uint256) {
        return _calculateExchangeRate(timestamp);
    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for minting ipToken
    function itfProvideLiquidity(uint256 assetAmount, uint256 timestamp) external {
        _provideLiquidity(assetAmount, _getDecimals(), timestamp);
    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for burning ipToken
    function itfRedeem(uint256 ipTokenAmount, uint256 timestamp) external {
        _redeem(ipTokenAmount, timestamp);
    }
}
