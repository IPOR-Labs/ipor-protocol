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

contract ItfJoseph is Joseph {
    uint256 internal immutable _decimals;
    bool internal immutable _overrideRedeemFeeRate;

    constructor(uint256 decimal, bool overrideRedeemFeeRate) {
        _decimals = decimal;
        _overrideRedeemFeeRate = overrideRedeemFeeRate;
    }

    function _getDecimals() internal view virtual override returns (uint256) {
        return _decimals;
    }

    function _getRedeemFeeRate() internal view virtual override returns (uint256) {
        return _overrideRedeemFeeRate ? 0 : _REDEEM_FEE_RATE;
    }

//    function itfCalculateExchangeRate(uint256 timestamp) external view returns (uint256) {
//        IMiltonInternal milton = _getMilton();
//        (, , int256 soap) = milton.calculateSoapAtTimestamp(timestamp);
//        return _calculateExchangeRate(soap, _getIpToken(), milton.getAccruedBalance().liquidityPool);
//    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for minting ipToken
    function itfProvideLiquidity(uint256 assetAmount, uint256 timestamp) external {
        _provideLiquidity(assetAmount, timestamp);
    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for burning ipToken
    function itfRedeem(uint256 ipTokenAmount, uint256 timestamp) external {
        _redeem(ipTokenAmount, timestamp);
    }
}
