// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJosephConfiguration {
    event CharlieTreasurerUpdated(address indexed asset, address indexed newCharlieTreasurer);

    event PublicationFeeTransfererUpdated(address indexed newPublicationFeeTransferer);

    event TreasuryTransfererUpdated(address indexed newTreasuryTransferer);

    event TreasuryTreasurerUpdated(address indexed asset, address indexed newTreasuryTreasurer);

    function getCharlieTreasurer() external view returns (address);

    function setCharlieTreasurer(address newCharlieTreasurer) external;

    function getTreasuryTreasurer() external view returns (address);

    function setTreasuryTreasurer(address newTreasuryTreasurer) external;

    function getPublicationFeeTransferer() external view returns (address);

    function setPublicationFeeTransferer(address newPublicationFeeTransferer) external;

    function getTreasuryTransferer() external view returns (address);

    function setTreasuryTransferer(address treasuryTransferer) external;

    function getRedeemFeePercentage() external pure returns (uint256);

    function getRedeemLpMaxUtilizationPercentage() external pure returns (uint256);

    function getMiltonStanleyBalancePercentage() external pure returns (uint256);

    function asset() external view returns (address);
}
