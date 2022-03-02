pragma solidity ^0.8.0;

// TODO: Use strict version
interface AaveLendingPoolProviderV2 {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);
}
