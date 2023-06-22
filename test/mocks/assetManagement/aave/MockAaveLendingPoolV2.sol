//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";
import "@ipor-protocol/contracts/vault/interfaces/aave/AaveLendingPoolV2.sol";
import "@ipor-protocol/contracts/vault/interfaces/aave/DataTypesContract.sol";
import "@ipor-protocol/contracts/vault/interfaces/aave/AToken.sol";
import "./MockADAI.sol";

contract MockAaveLendingPoolV2 is AaveLendingPoolV2 {
    address private _dai;
    address private _aDai;
    address private _stableDebtTokenAddress;
    address private _variableDebtTokenAddress;
    address private _interestRateStrategyAddress;
    uint128 private _currentLiquidityRate;

    constructor(address dai, address aDai) {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI asset address cannot be 0"));
        require(aDai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " aDAI asset address cannot be 0"));

        _dai = dai;
        _aDai = aDai;
    }

    function deposit(
        address,
        uint256 amount,
        address recipient,
        uint16
    ) external override {
        IERC20(_aDai).transfer(recipient, amount);
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

    function getReserveData(address reserve) external view override returns (DataTypesContract.ReserveData memory) {
        require(reserve != address(0));
        DataTypesContract.ReserveData memory d;
        d.stableDebtTokenAddress = _stableDebtTokenAddress;
        d.variableDebtTokenAddress = _variableDebtTokenAddress;
        d.interestRateStrategyAddress = _interestRateStrategyAddress;
        d.currentLiquidityRate = _currentLiquidityRate;
        return d;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        require(asset != address(0));
        AToken(_aDai).burn(msg.sender, to, amount, 0);
        return amount;
    }
}
