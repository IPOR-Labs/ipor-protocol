// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/StorageLib.sol";
import "../libraries/errors/IporErrors.sol";

library OwnerManager {
    event AppointedToTransferOwnership(address indexed appointedOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function getOwner() internal view returns (address) {
        return StorageLib.getOwner().owner;
    }

    function appointToOwnership(address newAppointedOwner) internal {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    function confirmAppointmentToOwnership() internal {
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        transferOwnership(msg.sender);
    }

    function renounceOwnership() internal {
        transferOwnership(address(0));
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    function transferOwnership(address newOwner) internal {
        StorageLib.OwnerStorage storage ownerStorage = StorageLib.getOwner();
        address oldOwner = address(ownerStorage.owner);
        ownerStorage.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
