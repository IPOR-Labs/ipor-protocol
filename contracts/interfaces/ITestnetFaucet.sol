// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

/// @title Interface for interaction with TestnetFaucet.
interface ITestnetFaucet {
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

    event Claim(
        /// @notice address to which stable were transfer
        address to,
        /// @notice underlying asset
        address asset,
        /// @notice amount of stable
        uint256 amount
    );
}
