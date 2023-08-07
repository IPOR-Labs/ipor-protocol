// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAmmTreasuryEth {
    function asset() external view returns (address);

    function router() external view returns (address);

    function getConfiguration() external view returns (address asset, address router);

    function getVersion() external pure returns (uint256);

    function pause() external;

    function unpause() external;

    function isPauseGuardian(address account) external view returns (bool);

    function addPauseGuardian(address guardian) external;

    function removePauseGuardian(address guardian) external;
}
