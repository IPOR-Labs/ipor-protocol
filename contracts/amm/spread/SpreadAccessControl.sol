// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/libraries/errors/MiltonErrors.sol";
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

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyAppointedOwner() {
        require(
            address(SpreadStorageLibs.getAppointedOwner().appointedOwner) == msg.sender,
            IporErrors.SENDER_NOT_APPOINTED_OWNER
        );
        _;
    }

    modifier onlyPauseGuardian() {
        PauseManager.isPauseGuardian(msg.sender);
        _;
    }

    function _onlyAmm() internal view {
        require(msg.sender == AMM_ADDRESS, MiltonErrors.SENDER_NOT_AMM);
    }

    function owner() external view returns (address) {
        return address(SpreadStorageLibs.getOwner().owner);
    }

    function transferOwnership(address newAppointedOwner) public onlyOwner {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    function confirmTransferOwnership() public onlyAppointedOwner {
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    function _onlyOwner() internal view {
        require(address(SpreadStorageLibs.getOwner().owner) == msg.sender, "Ownable: caller is not the owner");
    }

    function pause() external onlyPauseGuardian {
        _pause();
    }
    function _pause() internal {
        SpreadStorageLibs.getPaused().value = 1;
    }

    function unpause() external onlyOwner {
        SpreadStorageLibs.getPaused().value = 0;
    }

    function paused() external view returns (uint256) {
        return uint256(SpreadStorageLibs.getPaused().value);
    }

    function _whenNotPaused() internal view {
        require(uint256(SpreadStorageLibs.getPaused().value) != 0, "Pausable: paused");
    }

    function addPauseGuardian(address _guardian) external onlyOwner {
        PauseManager.addPauseGuardian(_guardian);
    }

    function removePauseGuardian(address _guardian) external onlyOwner {
        PauseManager.removePauseGuardian(_guardian);
    }

    function isPauseGuardian(address _guardian) external view returns (bool) {
        return PauseManager.isPauseGuardian(_guardian);
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
