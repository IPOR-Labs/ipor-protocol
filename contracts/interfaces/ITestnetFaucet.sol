// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Interface for interaction with TestnetFaucet.
interface ITestnetFaucet {

    /// @notice Return implementation version.
    function getVersion() external pure virtual returns (uint256);

    /// @notice Claim stable for amm system (Dai, Usdc, Usdt) it can be done ones every 24h.
    /// First time transfer 100 000 otherwise 10 000
    /// @dev Emits `Claim` event from TestnetFaucet, {Transfer} event from ERC20 asset.
    function claim() external;

    /// @notice Check if one can claim more stable
    /// @return number of seconds user have to wait till he will be able to claim new stable
    function couldClaimInSeconds() external view returns (uint256);

    function balanceOf(address asset) external view returns (uint256);

    /// @notice Check if user has calim stables before
    /// @return true if user calim before and false otherwise
    function hasClaimBefore() external view returns (bool);

    /// @notice Add new asset to faucet,
    /// @param asset address of asset to add to faucet
    /// @param amount amount of asset to transfer when user claim
    function addAsset(address asset, uint256 amount) external;

    /// @notice update amount of asset to transfer when user claim
    /// @param asset address of asset to add to faucet
    /// @param amount amount of asset to transfer when user claim
    function updateAmountToTransfer(address asset, uint256 amount) external;

    /// @notice amount of asset to transfer when user claim
    /// @param asset address of asset to add to faucet
    function amountToTransfer(address asset) external view returns (uint256);

    /// @notice transfer amount from faucet to user on asset, can be call only by owner
    /// @param asset address of asset to transfer from faucet
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
