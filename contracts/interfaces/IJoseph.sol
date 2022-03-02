// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJoseph {
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
        uint256 ipTokenValue
    );    

    function getVersion() external pure returns (uint256);

    function pause() external;

    function unpause() external;    

    function rebalance() external;

    function depositToVault(uint256 assetValue) external;

    function withdrawFromVault(uint256 assetValue) external;

    function provideLiquidity(uint256 liquidityAmount) external;

    function redeem(uint256 ipTokenVolume) external;

    //@notice Transfers asset value from Miltons's Treasure Balance to Treasure Treaserer account
    function transferTreasury(uint256 assetValue) external;

    //@notice Transfers asset value from Miltons's Ipor Publication Fee Balance to Charlie Treaserer account
    function transferPublicationFee(uint256 assetValue) external;

    function checkVaultReservesRatio() external returns (uint256);
}
