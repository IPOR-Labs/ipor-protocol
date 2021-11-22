// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IMilton {

    function authorizeJoseph(address asset) external;

    function pause() external;

    function unpause() external;

    function openPosition(address asset, uint256 totalAmount, uint256 maximumSlippage,
        uint256 collateralizationFactor, uint8 direction) external returns (uint256);

    function closePosition(uint256 derivativeId) external;

    function calculateSoap(address asset) external view returns (int256 soapPf, int256 soapRf, int256 soap);

    function calculateSpread(address asset) external view returns (uint256 spreadPf, uint256 spreadRf);

    function calculatePositionValue(DataTypes.IporDerivative memory derivative) external view returns (int256);

    function calculateExchangeRate(address asset, uint256 calculateTimestamp) external view returns (uint256);

}
