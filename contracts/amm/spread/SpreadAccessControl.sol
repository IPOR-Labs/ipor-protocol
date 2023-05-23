// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "contracts/security/PauseManager.sol";
import "./SpreadStorageLibs.sol";


contract SpreadAccessControl {
    event AppointedToTransferOwnership(address indexed appointedOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address internal immutable AMM_ADDRESS;

    constructor(address ammAddress) {
        require(ammAddress != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammAddress"));
        AMM_ADDRESS = ammAddress;
    }

    /// @dev Throws error if called by any account other than the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Throws error if called by any account other than the appointed owner.
    modifier onlyAppointedOwner() {
        require(
            address(SpreadStorageLibs.getAppointedOwner().appointedOwner) == msg.sender,
            IporErrors.SENDER_NOT_APPOINTED_OWNER
        );
        _;
    }

    /// @dev Throws if called by any account other than the pause guardian.
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    /// @notice Returns the address of the contract owner.
    /// @return The address of the contract owner.
    function owner() external view returns (address) {
        return SpreadStorageLibs.getOwner().owner;
    }

    /// @notice Transfers the ownership of the contract to a new appointed owner.
    /// @param newAppointedOwner The address of the new appointed owner.
    /// @dev Only the current contract owner can call this function.
    function transferOwnership(address newAppointedOwner) public onlyOwner {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    /// @notice Confirms the transfer of ownership by the appointed owner.
    /// @dev Only the appointed owner can call this function.
    function confirmTransferOwnership() public onlyAppointedOwner {
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    /// @notice Renounces the ownership of the contract.
    /// @dev Only the contract owner can call this function.
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    /// @notice Pauses the contract.
    /// @dev Only the pause guardian can call this function.
    function pause() external onlyPauseGuardian {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Only the contract owner can call this function.
    function unpause() external onlyOwner {
        SpreadStorageLibs.getPaused().value = 0;
    }

    /// @notice Returns the current pause status of the contract.
    /// @return The pause status represented as a uint256 value (0 for not paused, 1 for paused).
    function paused() external view returns (uint256) {
        return uint256(SpreadStorageLibs.getPaused().value);
    }

    /// @notice Adds a new pause guardian to the contract.
    /// @param _guardian The address of the new pause guardian.
    /// @dev Only the contract owner can call this function.
    function addPauseGuardian(address _guardian) external onlyOwner {
        PauseManager.addPauseGuardian(_guardian);
    }

    /// @notice Removes a pause guardian from the contract.
    /// @param _guardian The address of the pause guardian to be removed.
    /// @dev Only the contract owner can call this function.
    function removePauseGuardian(address _guardian) external onlyOwner {
        PauseManager.removePauseGuardian(_guardian);
    }

    /// @notice Checks if an address is a pause guardian.
    /// @param guardian The address to be checked.
    /// @return A boolean indicating whether the address is a pause guardian (true) or not (false).
    function isPauseGuardian(address guardian) external view returns (bool) {
        return PauseManager.isPauseGuardian(guardian);
    }

    /// @dev Internal function to check if the sender is the AMM address.
    function _onlyAmm() internal view {
        require(msg.sender == AMM_ADDRESS, AmmErrors.SENDER_NOT_AMM);
    }

    function _whenNotPaused() internal view {
        require(uint256(SpreadStorageLibs.getPaused().value) == 0, "Pausable: paused");
    }

    /// @dev Internal function to check if the sender is the contract owner.
    function _onlyOwner() internal view {
        require(address(SpreadStorageLibs.getOwner().owner) == msg.sender, "Ownable: caller is not the owner");
    }

    function _pause() internal {
        SpreadStorageLibs.getPaused().value = 1;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        SpreadStorageLibs.OwnerStorage storage ownerStorage = SpreadStorageLibs.getOwner();
        address oldOwner = address(ownerStorage.owner);
        ownerStorage.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
