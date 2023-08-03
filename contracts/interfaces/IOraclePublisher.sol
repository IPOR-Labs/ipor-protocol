// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interacting with IporProtocol oracles.
interface IOraclePublisher {
    /// @notice Returns current version of IOraclePublisher's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current OraclePublisher version
    function getVersion() external pure returns (uint256);

    function publish(address[] memory addresses, bytes[] calldata calls) external;

    /// @notice Adds new Updater. Updater has right to use OraclePublisher contract to publish index and risk management indicators. Function available only for Owner.
    /// @param newUpdater new updater address
    function addUpdater(address newUpdater) external;

    /// @notice Removes Updater. Function available only to Owner.
    /// @param updater updater address
    function removeUpdater(address updater) external;

    /// @notice Checks if given account is an Updater.
    /// @param account account for checking
    /// @return 0 if account is not updater, 1 if account is updater.
    function isUpdater(address account) external view returns (uint256);

    /// @notice Pauses current smart contract, it can be executed only by the Pause Guardian
    /// @dev Emits {Paused} event from IporOracle.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from IporOracle.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be added.
    function addPauseGuardian(address guardian) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be removed.
    function removePauseGuardian(address guardian) external;

    /// @notice event emitted when OraclePublisher Updater is added by Owner
    /// @param newUpdater new Updater address
    event OraclePublisherUpdaterAdded(address newUpdater);

    /// @notice event emitted when OraclePublisher Updater is removed by Owner
    /// @param updater updater address
    event OraclePublisherUpdaterRemoved(address updater);
}
