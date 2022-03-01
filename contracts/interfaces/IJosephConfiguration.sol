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

    function getCharlieTreasurer() external view returns (address);

    function setCharlieTreasurer(address newCharlieTreasurer) external;

    function getTreasureTreasurer() external view returns (address);

    function setTreasureTreasurer(address newTreasureTreasurer) external;

    function getPublicationFeeTransferer() external view returns (address);

    function setPublicationFeeTransferer(address newPublicationFeeTransferer)
        external;

    function getTreasureTransferer() external view returns (address);

    function setTreasureTransferer(address treasureTransferer) external;

    function getRedeemLpMaxUtilizationPercentage()
        external
        view
        returns (uint256);

    function getMiltonStanleyBalancePercentage()
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);

    function asset() external view returns (address);
}
