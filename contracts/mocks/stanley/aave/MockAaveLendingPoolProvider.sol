//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

// interfaces
import "../../../vault/interfaces/aave/AaveLendingPoolProviderV2.sol";

contract MockAaveLendingPoolProvider is AaveLendingPoolProviderV2 {
    address private _pool;
    address private _core;

    function getLendingPool() external view override returns (address) {
        return _pool;
    }

    function getLendingPoolCore() external view override returns (address) {
        return _core;
    }

    // mocked methods
    function _setLendingPool(address pool) external {
        _pool = pool;
    }

    function _setLendingPoolCore(address core) external {
        _core = core;
    }
}
