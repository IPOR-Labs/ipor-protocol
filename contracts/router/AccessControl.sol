// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

import "../libraries/errors/IporErrors.sol";
import "../libraries/StorageLib.sol";
import "../security/PauseManager.sol";
import "../security/OwnerManager.sol";

contract AccessControl {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    uint256 internal _reentrancyStatus;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyAppointedOwner() {
        require(
            address(StorageLib.getAppointedOwner().appointedOwner) == msg.sender,
            IporErrors.SENDER_NOT_APPOINTED_OWNER
        );
        _;
    }
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function owner() external view returns (address) {
        return OwnerManager.getOwner();
    }

    function appointToOwnership(address appointedOwner) public onlyOwner {
        OwnerManager.appointToOwnership(appointedOwner);
    }

    function confirmAppointmentToOwnership() public onlyAppointedOwner {
        OwnerManager.confirmAppointmentToOwnership();
    }

    function renounceOwnership() public virtual onlyOwner {
        OwnerManager.renounceOwnership();
    }

    function pause(bytes4[] calldata functionSigs) external onlyPauseGuardian {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 1;
            unchecked {
                ++i;
            }
        }
    }

    function unpause(bytes4[] calldata functionSigs) external onlyOwner {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 0;
            unchecked {
                ++i;
            }
        }
    }

    function paused(bytes4 functionSig) external view returns (uint256) {
        return StorageLib.getRouterFunctionPaused().value[functionSig];
    }

    function addPauseGuardian(address guardian) external onlyOwner {
        PauseManager.addPauseGuardian(guardian);
    }

    function removePauseGuardian(address guardian) external onlyOwner {
        PauseManager.removePauseGuardian(guardian);
    }

    function isPauseGuardian(address guardian) external view returns (bool) {
        return PauseManager.isPauseGuardian(guardian);
    }

    function _checkFunctionSigAndIsNotPause(bytes4 functionSig, bytes4 expectedSig) internal view returns (bool) {
        if (functionSig == expectedSig) {
            require(StorageLib.getRouterFunctionPaused().value[functionSig] == 0, IporErrors.METHOD_PAUSED);
            return true;
        }
        return false;
    }

    function _onlyOwner() internal view {
        require(address(StorageLib.getOwner().owner) == msg.sender, IporErrors.CALLER_NOT_OWNER);
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
