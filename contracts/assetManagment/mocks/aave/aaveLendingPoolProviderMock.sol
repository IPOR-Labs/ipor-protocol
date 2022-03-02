pragma solidity ^0.8.0;

// interfaces
import "../../interfaces/aave/AaveLendingPoolProviderV2.sol";

contract aaveLendingPoolProviderMock is AaveLendingPoolProviderV2 {
  address public pool;
  address public core;

  function getLendingPool() external override view returns (address) {
    return pool;
  }
  function getLendingPoolCore() external override view returns (address) {
    return core;
  }

  // mocked methods
  function _setLendingPool(address _pool) external {
    pool = _pool;
  }
  function _setLendingPoolCore(address _core) external {
    core = _core;
  }
}
