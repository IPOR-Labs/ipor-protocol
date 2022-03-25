// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJosephConfiguration {
    event CharlieTreasuryUpdated(address indexed asset, address indexed newCharlieTreasury);

    event CharlieTreasuryManagerUpdated(address indexed newCharlieTreasuryManager);

    event TreasuryManagerUpdated(address indexed newTreasuryManager);

    event TreasuryUpdated(address indexed asset, address indexed newTreasury);

    function getCharlieTreasury() external view returns (address);

    function setCharlieTreasury(address newCharlieTreasury) external;

    function getTreasury() external view returns (address);

    function setTreasury(address newTreasury) external;

    function getCharlieTreasuryManager() external view returns (address);

    function setCharlieTreasuryManager(address newCharlieTreasuryManager) external;

    function getTreasuryManager() external view returns (address);

    function setTreasuryManager(address treasuryManager) external;

    function getRedeemFeePercentage() external pure returns (uint256);

    function getRedeemLpMaxUtilizationPercentage() external pure returns (uint256);

    function getMiltonStanleyBalancePercentage() external pure returns (uint256);

    function asset() external view returns (address);
}
