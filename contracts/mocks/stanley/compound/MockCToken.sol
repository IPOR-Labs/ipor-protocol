//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libraries/Constants.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../vault/interfaces/compound/CErc20Mock.sol";

contract MockCToken is ERC20, CErc20Mock {
    address private _asset;
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
    uint8 private _detiomal;

    constructor(
        address asset,
        address interestRateModel,
        uint8 decimal,
        string memory name,
        string memory code
    ) public ERC20(name, code) {
        _asset = asset;
        _interestRateModel = interestRateModel;
        _detiomal = decimal;
        _exchangeRate = 1325321471291866029;
        _supplyRate = 32847953230;
        _mint(address(this), 10**14); // 1.000.000 cToken
        _mint(msg.sender, 10**13); // 100.000 cToken
    }

    function decimals() public view override returns (uint8) {
        return _detiomal;
    }

    function setSupplyRate(uint128 v) public {
        _supplyRate = v;
    }

    function mint(uint256 amount) external override returns (uint256) {
        require(
            IERC20(_asset).transferFrom(msg.sender, address(this), amount),
            "Error during transferFrom"
        );
        _mint(msg.sender, IporMath.division((amount * Constants.D18), _exchangeRate));

        return 0;
    }

    function redeem(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount);
        require(
            IERC20(_asset).transfer(
                msg.sender,
                IporMath.division(amount * _exchangeRate, Constants.D18)
            ),
            "Error during transfer"
        );
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

    function exchangeRateCurrent() external override returns (uint256) {}

    function accrueInterest() external override returns (uint256) {}
}
