// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

contract MockMiltonForStanley {
    address private _asset;

    constructor(address asset) {
        _asset = asset;
    }

    function getAsset() external view returns (address) {
        return _asset;
    }
}
