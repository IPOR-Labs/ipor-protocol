// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "../libraries/errors/IporErrors.sol";

contract AccessControl {
    event AppointedToTransferOwnership(address indexed appointedOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address internal _owner;
    address private _appointedOwner;
    //    _paused = 1 means paused
    //    _paused = 0 means not paused
    uint256 internal _paused;
    //    _paused = 1 means is Guardians
    //    _paused = 0 means is not Guardian
    mapping(address => uint256) internal pauseGuardians;

    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _reentrancyStatus;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    modifier onlyAppointedOwner() {
        require(_appointedOwner == msg.sender, IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }
    modifier onlyPauseGuardian() {
        require(pauseGuardians[msg.sender] == 1, IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function transferOwnership(address appointedOwner) public onlyOwner {
        require(appointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    function confirmTransferOwnership() public onlyAppointedOwner {
        _appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        _appointedOwner = address(0);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function pause() external onlyPauseGuardian {
        _paused = 1;
    }

    function unpause() external onlyOwner {
        _paused = 0;
    }

    function paused() external view returns (uint256) {
        return _paused;
    }

    function addPauseGuardian(address _guardian) external onlyOwner {
        pauseGuardians[_guardian] = 1;
    }

    function removePauseGuardian(address _guardian) external onlyOwner {
        pauseGuardians[_guardian] = 0;
    }

    function _onlyOwner() internal view {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
    }

    function whenNotPaused() internal view {
        require(_paused == 0, "Pausable: paused");
    }

    function nonReentrant() internal view {
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
