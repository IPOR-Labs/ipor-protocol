//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/vault/interfaces/compound/CErc20Mock.sol";

contract MockCDAI is ERC20, CErc20Mock {
    address private _dai;
    uint256 private _toTransfer;
    uint256 private _toMint;
    address private _interestRateModel;
    uint256 private _supplyRate;
    uint256 private _exchangeRate;
    uint256 private _totalBorrows;
    uint256 private _totalReserves;
    uint256 private _reserveFactorMantissa;
    uint256 private _getCash;
    address private _comptroller;

    constructor(address dai, address interestRateModel) public ERC20("cDAI", "cDAI") {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI asset address cannot be 0"));
        require(interestRateModel != address(0), string.concat(IporErrors.WRONG_ADDRESS, " interest rate model address cannot be 0"));

        _dai = dai;
        _interestRateModel = interestRateModel;
        _exchangeRate = 200000000000000000;
        _supplyRate = 32847953230;
        _mint(address(this), 10**14); // 1.000.000 cDAI
        _mint(msg.sender, 10**13); // 100.000 cDAI
    }

    function decimals() public pure override returns (uint8) {
        return 16;
    }

    function setSupplyRate(uint128 v) public {
        _supplyRate = v;
    }

    function mint(uint256 amount) external override returns (uint256) {
        require(IERC20(_dai).transferFrom(msg.sender, address(this), amount), "Error during transferFrom"); // 1 DAI
        _mint(msg.sender, IporMath.division((amount * 10**18), _exchangeRate));

        return 0;
    }

    function redeem(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount);
        require(
            IERC20(_dai).transfer(msg.sender, IporMath.division(amount * _exchangeRate, 10**18)),
            "Error during transfer"
        ); // 1 DAI
        return 0;
    }

    function setParams(uint256[] memory params) external {
        _totalBorrows = params[2];
        _totalReserves = params[4];
        _reserveFactorMantissa = 50000000000000000;
        _getCash = params[6];
    }

    function borrowRatePerBlock() external view returns (uint256) {}

    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRate;
    }

    function setExchangeRateStored(uint256 rate) external returns (uint256) {
        _exchangeRate = rate;
        return _exchangeRate;
    }

    function setComptroller(address comp) external {
        _comptroller = comp;
    }

    function supplyRatePerBlock() external view override returns (uint256) {
        return _supplyRate;
    }

    function totalReserves() external view returns (uint256) {
        return _totalReserves;
    }

    function getCash() external view returns (uint256) {
        return _getCash;
    }

    function totalBorrows() external view returns (uint256) {
        return _totalBorrows;
    }

    function reserveFactorMantissa() external view returns (uint256) {
        return _reserveFactorMantissa;
    }

    function interestRateModel() external view returns (address) {
        return _interestRateModel;
    }

    function comptroller() external view returns (address) {
        return _comptroller;
    }

    function underlying() external view returns (address) {}

    function exchangeRateCurrent() external view override returns (uint256) {}

    function accrueInterest() external override returns (uint256) {}
}
