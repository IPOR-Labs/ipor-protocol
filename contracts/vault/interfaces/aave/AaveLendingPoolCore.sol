// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface AaveLendingPoolCore {
    function getReserveCurrentLiquidityRate(address reserve) external view returns (uint256);

    function getReserveInterestRateStrategyAddress(address reserve) external view returns (address);

    function getReserveTotalBorrowsStable(address reserve) external view returns (uint256);

    function getReserveTotalBorrowsVariable(address reserve) external view returns (uint256);

    function getReserveCurrentAverageStableBorrowRate(address reserve)
        external
        view
        returns (uint256);

    function getReserveAvailableLiquidity(address reserve) external view returns (uint256);
}
