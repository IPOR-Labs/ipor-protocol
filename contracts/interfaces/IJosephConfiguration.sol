// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJosephConfiguration {
    event CharlieTreasurerUpdated(
        address indexed asset,
        address indexed newCharlieTreasurer
    );

    event PublicationFeeTransfererUpdated(
        address indexed newPublicationFeeTransferer
    );

    event TreasureTransfererUpdated(address indexed newTreasureTransferer);

    event TreasureTreasurerUpdated(
        address indexed asset,
        address indexed newTreasureTreasurer
    );

    function setCharlieTreasurer(address newCharlieTreasurer) external;

    function setTreasureTreasurer(address newTreasureTreasurer) external;

    function setPublicationFeeTransferer(address newPublicationFeeTransferer)
        external;

    function setTreasureTransferer(address treasureTransferer) external;

    function decimals() external view returns (uint8);

    function asset() external view returns (address);
}
