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

	function checkVaultReservesRatio() external returns(uint256);
	function rebalance() external;
	function depositToVault(uint256 assetAmount) external;
	function withdrawFromVault(uint256 ivTokenAmount) external;

    function decimals() external view returns (uint8);

    function asset() external view returns (address);

    function provideLiquidity(uint256 liquidityAmount) external;

    function redeem(uint256 ipTokenVolume) external;
}
