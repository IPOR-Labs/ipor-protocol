// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Interface for interaction with TestnetFaucet.
interface ITestnetFaucet {
    /// @notice Claim stable for amm system (Dai, Usdc, Usdt) it can be done ones every 24h.
    /// First time transfer 100 000 otherwise 10 000
    /// @dev Emits `Claim` event from TestnetFaucet, {Transfer} event from ERC20 asset.
    function claim() external;

    /// @notice Check if one can claim more stable
    /// @return number of seconds user have to wait till he will be able to claim new stable
    function couldClaimInSeconds() external view returns (uint256);

    /// @notice Checks balance of faucet
    /// @param asset address for which one want to get balance
    /// @return balance of faucet for the asset
    function balanceOf(address asset) external view returns (uint256);

    /// @notice Check if user has calim stables before
    /// @return true if user claim before and false otherwise
    function hasClaimBefore() external view returns (bool);

    /// @notice Add new asset to faucet
    /// @param asset address.
    function addAsset(address asset) external;

    /// @notice removes asset from faucet
    /// @param asset address.
    function removeAsset(address asset) external;

    /// @notice Checks if asset is active in the faucet
    /// @param asset address.
    /// @return true if asset is active and false otherwise
    function isAssetActive(address asset) external view returns(bool);

    event Claim(
        /// @notice address to which stable were transfer
        address to,
        /// @notice underlying asset
        address asset,
        /// @notice amount of stable
        uint256 amount
    );
}
