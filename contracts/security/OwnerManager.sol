// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../libraries/errors/IporErrors.sol";
import {StorageLibBaseV1} from "../base/libraries/StorageLibBaseV1.sol";

/// @title Ipor Protocol Router Owner Manager library
library OwnerManager {
    /// @notice Emitted when account is appointed to transfer ownership
    /// @param appointedOwner Address of appointed owner
    event AppointedToTransferOwnership(address indexed appointedOwner);

    /// @notice Emitted when ownership is transferred
    /// @param previousOwner Address of previous owner
    /// @param newOwner Address of new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Gets the current owner of Ipor Protocol Router
    function getOwner() internal view returns (address) {
        return StorageLibBaseV1.getOwner().owner;
    }

    /// @notice Oppoint account to transfer ownership
    /// @param newAppointedOwner Address of appointed owner
    function appointToOwnership(address newAppointedOwner) internal {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        StorageLibBaseV1.AppointedOwnerStorage storage appointedOwnerStorage = StorageLibBaseV1.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    /// @notice Confirm appointment to ownership
    /// @dev This is real transfer ownership in second step by appointed account
    function confirmAppointmentToOwnership() internal {
        StorageLibBaseV1.AppointedOwnerStorage storage appointedOwnerStorage = StorageLibBaseV1.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        transferOwnership(msg.sender);
    }

    /// @notice Renounce ownership
    function renounceOwnership() internal {
        transferOwnership(address(0));
        StorageLibBaseV1.AppointedOwnerStorage storage appointedOwnerStorage = StorageLibBaseV1.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    /// @notice Immediately transfers ownership
    function transferOwnership(address newOwner) internal {
        StorageLibBaseV1.OwnerStorage storage ownerStorage = StorageLibBaseV1.getOwner();
        address oldOwner = ownerStorage.owner;
        ownerStorage.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
