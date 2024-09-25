// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

interface IAsset {
    function approve(address _spender, uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);
}
