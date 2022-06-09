//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../vault/interfaces/aave/AaveLendingPool.sol";
import "../../../vault/interfaces/aave/DataTypesContract.sol";

contract MockAaveLendingPool is AaveLendingPool {
    address private _dai;
    address private _aDai;
    address private _stableDebtTokenAddress;
    address private _variableDebtTokenAddress;
    address private _interestRateStrategyAddress;
    uint128 private _currentLiquidityRate;

    constructor(address dai, address aDai) {
        _dai = dai;
        _aDai = aDai;
    }

    function deposit(
        address,
        uint256 amount,
        uint16
    ) external override {
        /* require(IERC20(_dai).transferFrom(msg.sender, address(this), _amount), "Error during transferFrom"); */
        IERC20(_aDai).transfer(msg.sender, amount);
    }

    function setStableDebtTokenAddress(address a) external {
        _stableDebtTokenAddress = a;
    }

    function setVariableDebtTokenAddress(address a) external {
        _variableDebtTokenAddress = a;
    }

    function setInterestRateStrategyAddress(address a) external {
        _interestRateStrategyAddress = a;
    }

    function setCurrentLiquidityRate(uint128 v) external {
        _currentLiquidityRate = v;
    }

    function getReserveData(address reserve)
        external
        view
        override
        returns (DataTypesContract.ReserveData memory)
    {
        DataTypesContract.ReserveData memory d;
        d.stableDebtTokenAddress = _stableDebtTokenAddress;
        d.variableDebtTokenAddress = _variableDebtTokenAddress;
        d.interestRateStrategyAddress = _interestRateStrategyAddress;
        d.currentLiquidityRate = _currentLiquidityRate;
        return d;
    }
}
