// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

interface StakedAaveInterface {
    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function stakersCooldowns(address user) external view returns (uint256);

    //solhint-disable func-name-mixedcase
    function COOLDOWN_SECONDS() external view returns (uint256);

    //solhint-disable func-name-mixedcase
    function UNSTAKE_WINDOW() external view returns (uint256);
}
