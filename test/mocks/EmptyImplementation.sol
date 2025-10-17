// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract EmptyImplementation {

    address private _asset;

    constructor(address asset_) {
        _asset = asset_;
    }

    function asset() external view returns (address) {
        return _asset;
    }

    fallback() external payable {
        revert("EmptyImplementation: fallback");
    }
}
