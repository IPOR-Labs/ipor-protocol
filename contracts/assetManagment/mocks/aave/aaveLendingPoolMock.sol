pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/aave/AaveLendingPool.sol";
import "../../interfaces/aave/DataTypes.sol";

contract AaveLendingPoolMock is AaveLendingPool {
    address internal _dai;
    address internal _aDai;
    address internal _stableDebtTokenAddress;
    address internal _variableDebtTokenAddress;
    address internal _interestRateStrategyAddress;
    uint128 internal _currentLiquidityRate;

    constructor(address dai, address aDai) public {
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

    function setStableDebtTokenAddress(address a) public {
        _stableDebtTokenAddress = a;
    }

    function setVariableDebtTokenAddress(address a) public {
        _variableDebtTokenAddress = a;
    }

    function setInterestRateStrategyAddress(address a) public {
        _interestRateStrategyAddress = a;
    }

    function setCurrentLiquidityRate(uint128 v) public {
        _currentLiquidityRate = v;
    }

    function getReserveData(address reserve)
        external
        view
        override
        returns (DataTypes.ReserveData memory)
    {
        DataTypes.ReserveData memory d;
        d.stableDebtTokenAddress = _stableDebtTokenAddress;
        d.variableDebtTokenAddress = _variableDebtTokenAddress;
        d.interestRateStrategyAddress = _interestRateStrategyAddress;
        d.currentLiquidityRate = _currentLiquidityRate;
        return d;
    }
}
