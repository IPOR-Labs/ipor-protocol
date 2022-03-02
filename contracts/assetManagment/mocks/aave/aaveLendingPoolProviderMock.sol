pragma solidity 0.8.9;

// interfaces
import "../../interfaces/aave/AaveLendingPoolProviderV2.sol";

contract AaveLendingPoolProviderMock is AaveLendingPoolProviderV2 {
    address internal _pool;
    address internal _core;

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
