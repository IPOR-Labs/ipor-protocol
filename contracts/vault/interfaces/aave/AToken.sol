// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

interface AToken {
    function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;
}
