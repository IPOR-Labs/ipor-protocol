// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStrategy {
    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Strategy instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    function getShareToken() external view returns (address);

    function getApr() external view returns (uint256);

    //@notice return amount of asset token (stable tokens)
    function balanceOf() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function beforeClaim() external;

    function doClaim() external;

    function setStanley(address stanley) external;

    function setTreasury(address treasury) external;

    function setTreasuryManager(address manager) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Strategy implementation.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Strategy implementation.
    function unpause() external;

    event StanleyChanged(address sender, address newStanley, address strategy);
    // TODO: ADD test for events into fork test
    event DoClaim(address strategy, address[] assets, address claimAddress, uint256 amount);

    event DoBeforeClaim(address strategy, address[] assets);

    event TreasuryChanged(address strategy, address newTreasury);

    event SetTreasuryManager(address strategy, address newTreasuryManager);

    event TreasuryManagerChanged(address strategy, address newTreasuryManager);

    event StkAaveChanged(address changedBy, address newStkAave);
}
