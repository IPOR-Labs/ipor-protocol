// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

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

    function pause() external onlyPauseGuardian {
        _pause();
    }

    function unpause() external onlyOwner {
        StorageLib.getPaused().value = 0;
    }

    function paused() external view returns (uint256) {
        return uint256(StorageLib.getPaused().value);
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

    function _onlyOwner() internal view {
        require(OwnerManager.getOwner() == msg.sender, "Ownable: caller is not the owner");
    }

    function _whenNotPaused() internal view {
        require(uint256(StorageLib.getPaused().value) == 0, "Pausable: paused");
    }

    function _pause() internal {
        StorageLib.getPaused().value = 1;
    }

    function _nonReentrant() internal view {
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
    }
}
