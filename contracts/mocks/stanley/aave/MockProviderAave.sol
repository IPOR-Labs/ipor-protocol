// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

contract MockProviderAave {
    address private _lendingPool;

    constructor(address lendingPool) {
        _lendingPool = lendingPool;
    }

    function getLendingPool() external view returns (address) {
        return _lendingPool;
    }
}
