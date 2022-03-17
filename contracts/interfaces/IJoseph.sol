// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJoseph {
    function getVersion() external pure returns (uint256);

    function provideLiquidity(uint256 liquidityAmount) external;

    function redeem(uint256 ipTokenVolume) external;

    function rebalance() external;

    function depositToStanley(uint256 assetValue) external;

    function withdrawFromStanley(uint256 assetValue) external;

    //@notice Transfers asset value from Miltons's Treasury Balance to Treasury Treaserer account
    function transferTreasury(uint256 assetValue) external;

    //@notice Transfers asset value from Miltons's Ipor Publication Fee Balance to Charlie Treaserer account
    function transferPublicationFee(uint256 assetValue) external;

    function checkVaultReservesRatio() external returns (uint256);

    function pause() external;

    function unpause() external;

    event ProvideLiquidity(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 assetValue,
        uint256 ipTokenValue
    );
    event Redeem(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 assetValue,
        uint256 ipTokenValue,
        uint256 redeemFee,
        uint256 redeemValue
    );
}
