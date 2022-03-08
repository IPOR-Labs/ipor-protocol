pragma solidity 0.8.9;

contract MockProviderAave {
    address private _lendingPool;

    constructor(address lendingPool) {
        _lendingPool = lendingPool;
    }

    function getLendingPool() external view returns (address) {
        return _lendingPool;
    }
}
