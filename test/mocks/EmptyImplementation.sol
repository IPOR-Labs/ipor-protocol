// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract EmptyImplementation {
    fallback() external payable {
        revert("EmptyImplementation: fallback");
    }
}
