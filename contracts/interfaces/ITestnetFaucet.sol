// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interacting with TestnetFaucet.
interface ITestnetFaucet {

    /// @notice Returns implementation version.
    function getVersion() external pure returns (uint256);

    /// @notice Claims stable for amm system (Dai, Usdc, Usdt) it can be done ones every 24h.
    /// First time transfer 100 000 otherwise 10 000
    /// @dev Emits `Claim` event from TestnetFaucet, {Transfer} event from ERC20 asset.
    function claim() external;

    /// @notice Checks if one can claim more stable
    /// @return number of seconds user havs to wait till they can claim new stable
    function couldClaimInSeconds() external view returns (uint256);

    function balanceOf(address asset) external view returns (uint256);

    /// @notice Checks if user had calimed stables before
    /// @return true if user had calimed before, otherwise false 
    function hasClaimBefore() external view returns (bool);

    /// @notice Adds new asset to the faucet,
    /// @param asset address of asset to be added to the faucet
    /// @param amount amount of asset to transfer when user claims
    function addAsset(address asset, uint256 amount) external;

    /// @notice updates amount of asset to transfer when user claims
    /// @param asset address of asset to be added to the faucet
    /// @param amount amount of asset to transfer when user claims
    function updateAmountToTransfer(address asset, uint256 amount) external;

    /// @notice amount of asset to transfer when user claims
    /// @param asset address of asset to add to faucet
    function getAmountToTransfer(address asset) external view returns (uint256);

    /// @notice transfers amount from faucet to user on asset, can be call only by owner
    /// @param asset address of asset to be transfered from faucet
    /// @param amount to transfer from faucet to user
    function transfer(address asset, uint256 amount) external;

    event Claim(
        /// @notice address to which stable were transfer
        address to,
        /// @notice underlying asset
        address asset,
        /// @notice amount of stable
        uint256 amount
    );

    event TransferFailed(
    /// @notice address to which stable were transfer
        address to,
    /// @notice underlying asset
        address asset,
    /// @notice amount of stable
        uint256 amount
    );
}
