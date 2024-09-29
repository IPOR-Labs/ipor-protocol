// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.26;

interface IRouterAccessControl {
    function owner() external view returns (address);

    function appointToOwnership(address appointedOwner) external;

    function confirmAppointmentToOwnership() external;

    function renounceOwnership() external;

    function paused(bytes4 functionSig) external view returns (uint256);

    function pause(bytes4[] calldata functionSigs) external;

    function unpause(bytes4[] calldata functionSigs) external;

    function isPauseGuardian(address account) external view returns (bool);

    function addPauseGuardians(address[] calldata guardians) external;

    function removePauseGuardians(address[] calldata guardians) external;
}
