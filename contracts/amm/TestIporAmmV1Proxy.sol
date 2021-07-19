// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./IporAmmV1.sol";

contract TestIporAmmV1Proxy is IporAmmV1 {

    constructor(address iporOracleAddr, address usdtToken, address usdcToken, address daiToken) IporAmmV1(iporOracleAddr, usdtToken, usdcToken, daiToken) {
    }

    function test_openPosition(
        uint256 openTimestamp,
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) public {
        _openPosition(openTimestamp, asset, totalAmount, maximumSlippage, leverage, direction);
    }

    function test_closePosition(uint256 derivativeId, uint256 closeTimestamp) public {
        _closePosition(derivativeId, closeTimestamp);
    }
}