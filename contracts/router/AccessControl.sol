// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;
import "../libraries/errors/IporErrors.sol";
import "../libraries/StorageLib.sol";
import "../security/PauseManager.sol";
import "../security/OwnerManager.sol";

/// @title Smart contract reponsible for managing access to administative functions in IporProtocolRouter
contract AccessControl {
    /// @dev Reentrancy - flag when thread is left method
    uint256 internal constant _NOT_ENTERED = 1;
    /// @dev Reentrancy - flag when thread is entered to method
    uint256 internal constant _ENTERED = 2;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Checks if sender is owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @notice Checks if sender is appointed owner
    modifier onlyAppointedOwner() {
        require(StorageLib.getAppointedOwner().appointedOwner == msg.sender, IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }

    /// @notice Checks if sender is pause guardian
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    /// @notice Steps before and after method execution to prevent reentrancy
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /// @notice Gets IPOR Protocol Owner on Router
    /// @return IPOR Protocol Owner address
    function owner() external view returns (address) {
        return OwnerManager.getOwner();
    }

    /// @notice Appoint new account to ownership
    /// @param appointedOwner New appointed owner address
    function appointToOwnership(address appointedOwner) public onlyOwner {
        OwnerManager.appointToOwnership(appointedOwner);
    }

    /// @notice Confirm appointed ownership
    function confirmAppointmentToOwnership() public onlyAppointedOwner {
        OwnerManager.confirmAppointmentToOwnership();
    }

    /// @notice Renounce ownership
    function renounceOwnership() public virtual onlyOwner {
        OwnerManager.renounceOwnership();
    }

    /// @notice Checks if function is paused
    /// @param functionSig Function signature
    /// @return 1 if function is paused, 0 otherwise
    function paused(bytes4 functionSig) external view returns (uint256) {
        return StorageLib.getRouterFunctionPaused().value[functionSig];
    }

    /// @notice Pauses list of functions in IporProtocolRouter
    /// @dev Can be called only by pause guardian
    function pause(bytes4[] calldata functionSigs) external onlyPauseGuardian {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 1;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Unpauses list of functions in IporProtocolRouter
    /// @dev Can be called only by Owner of Ipor Protocol Router
    function unpause(bytes4[] calldata functionSigs) external onlyOwner {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 0;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks if address is pause guardian
    /// @param account Pause guardian address
    /// @return true if address is pause guardian, false otherwise
    function isPauseGuardian(address account) external view returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    /// @notice Adds new pause guardians
    /// @param guardians List of new pause guardians addresses
    function addPauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    /// @notice Removes pause guardian
    /// @param guardians List of pause guardians addresses
    function removePauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function _checkFunctionSigAndIsNotPause(bytes4 functionSig, bytes4 expectedSig) internal view returns (bool) {
        if (functionSig == expectedSig) {
            require(StorageLib.getRouterFunctionPaused().value[functionSig] == 0, IporErrors.METHOD_PAUSED);
            return true;
        }
        return false;
    }

    function _onlyOwner() internal view {
        require(StorageLib.getOwner().owner == msg.sender, IporErrors.CALLER_NOT_OWNER);
    }

    function _nonReentrantBefore() internal {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(StorageLib.getReentrancyStatus().value != _ENTERED, IporErrors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        StorageLib.getReentrancyStatus().value = _ENTERED;
    }

    function _nonReentrantAfter() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        if (StorageLib.getReentrancyStatus().value == _ENTERED) {
            StorageLib.getReentrancyStatus().value = _NOT_ENTERED;
        }
    }
}
