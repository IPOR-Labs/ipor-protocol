// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

interface ComptrollerInterface {
    function claimComp(address holder) external;

    function claimComp(address holder, address[] calldata) external;

    function claimComp(
        address[] calldata holders,
        address[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;
}
