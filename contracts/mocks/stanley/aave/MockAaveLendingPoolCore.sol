// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

// interfaces
import "../../../vault/interfaces/aave/AaveLendingPoolCore.sol";

contract MockAaveLendingPoolCore is AaveLendingPoolCore {
    address private _reserve;
    uint256 private _liquidity;
    uint256 private _borrowsStable;
    uint256 private _borrowsVariable;
    uint256 private _stableBorrowRate;
    uint256 private _apr;

    function getReserveInterestRateStrategyAddress(address)
        external
        view
        override
        returns (address)
    {
        return _reserve;
    }

    function setReserve(address reserve) external {
        _reserve = reserve;
    }

    function getReserveAvailableLiquidity(address) external view override returns (uint256) {
        return _liquidity;
    }

    function setReserveAvailableLiquidity(uint256 newVal) external {
        _liquidity = newVal;
    }

    function getReserveTotalBorrowsStable(address) external view override returns (uint256) {
        return _borrowsStable;
    }

    function setReserveTotalBorrowsStable(uint256 newVal) external {
        _borrowsStable = newVal;
    }

    function getReserveTotalBorrowsVariable(address) external view override returns (uint256) {
        return _borrowsVariable;
    }

    function setReserveTotalBorrowsVariable(uint256 newVal) external {
        _borrowsVariable = newVal;
    }

    function getReserveCurrentAverageStableBorrowRate(address)
        external
        view
        override
        returns (uint256)
    {
        return _stableBorrowRate;
    }

    function setReserveCurrentAverageStableBorrowRate(uint256 newVal) external {
        _stableBorrowRate = newVal;
    }

    function getReserveCurrentLiquidityRate(address)
        external
        view
        override
        returns (uint256 liquidityRate)
    {
        return _apr;
    }

    function setReserveCurrentLiquidityRate(uint256 newVal) external {
        _apr = newVal;
    }
}
