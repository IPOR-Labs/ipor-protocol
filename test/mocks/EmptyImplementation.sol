// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

contract EmptyImplementation {
    fallback() external payable {
        revert("EmptyImplementation: fallback");
    }
}
