// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./MiltonV1.sol";

contract TestMiltonV1Proxy is MiltonV1 {

    constructor(IMiltonAddressesManager addressesManager) MiltonV1(addressesManager) {}

    function test_openPosition(
        uint256 openTimestamp,
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) public returns (uint256) {
        return _openPosition(openTimestamp, DataTypes.stringToBytes32(asset), totalAmount, maximumSlippage, leverage, direction);
    }

    function test_closePosition(uint256 derivativeId, uint256 closeTimestamp) public {
        _closePosition(derivativeId, closeTimestamp);
    }

    function test_calculateSoap(
        string memory asset,
        uint256 calculateTimestamp) public view returns (int256 soapPf, int256 soapRf, int256 soap){
        return _calculateSoap(DataTypes.stringToBytes32(asset), calculateTimestamp);
    }

    function test_calculateSpread(
        string memory asset,
        uint256 calculateTimestamp) public view returns (uint256 spreadPf, uint256 spreadRf){
        return _calculateSpread(DataTypes.stringToBytes32(asset), calculateTimestamp);
    }

    function getUserDerivativeIds(address userAddress) public view returns (uint256[] memory) {
        return derivatives.userDerivativeIds[userAddress];
    }

    function getDerivativeIds() public view returns (uint256[] memory) {
        return derivatives.ids;
    }

    function getDerivativeItem(uint256 derivativeId) public view returns (DataTypes.MiltonDerivativeItem memory) {
        return derivatives.items[derivativeId];
    }
}