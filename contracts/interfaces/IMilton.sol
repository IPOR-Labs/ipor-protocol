// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMilton {

    function openPosition(string memory asset, uint256 totalAmount, uint256 maximumSlippage, uint8 leverage, uint8 direction) external returns (uint256);

    function closePosition(uint256 derivativeId) external;

    function provideLiquidity(string memory asset, uint256 liquidityAmount) external;

    function calculateSoap(string memory asset) external view returns (int256 soapPf, int256 soapRf, int256 soap);

    //TODO: final implementation
    function calculateSpread(string memory asset) external view returns (uint256 spreadPf, uint256 spreadRf);

}
