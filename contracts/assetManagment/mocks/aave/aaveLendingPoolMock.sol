pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/aave/AaveLendingPool.sol";
import "../../interfaces/aave/DataTypes.sol";

contract aaveLendingPoolMock is AaveLendingPool {
  address public dai;
  address public aDai;
  address public stableDebtTokenAddress;
  address public variableDebtTokenAddress;
  address public interestRateStrategyAddress;
  uint128 public currentLiquidityRate;

  constructor (address _dai, address _aDai) public {
    dai = _dai;
    aDai = _aDai;
  }

  function deposit(address, uint256 _amount, uint16) external override {
    /* require(IERC20(dai).transferFrom(msg.sender, address(this), _amount), "Error during transferFrom"); */
    IERC20(aDai).transfer(msg.sender, _amount);
  }

  function setStableDebtTokenAddress(address a) public {
    stableDebtTokenAddress = a;
  }

  function setVariableDebtTokenAddress(address a) public {
    variableDebtTokenAddress = a;
  }

  function setInterestRateStrategyAddress(address a) public {
    interestRateStrategyAddress = a;
  }

  function setCurrentLiquidityRate(uint128 v) public {
    currentLiquidityRate = v;
  }

  function getReserveData(address _reserve) external override view returns(DataTypes.ReserveData memory) {
    DataTypes.ReserveData memory d;
    d.stableDebtTokenAddress = stableDebtTokenAddress;
    d.variableDebtTokenAddress = variableDebtTokenAddress;
    d.interestRateStrategyAddress = interestRateStrategyAddress;
    d.currentLiquidityRate = currentLiquidityRate;
    return d;
  }
}
