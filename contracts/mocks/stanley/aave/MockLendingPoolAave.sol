//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../../vault/interfaces/aave/DataTypesContract.sol";
import "./aTokens/MockIAToken.sol";

contract MockLendingPoolAave {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    // asset(dai/usdt/usdc) => adai/ausdt/ausdc
    mapping(address => address) _aTokens;

    // mapping(address => MockReserveData) _liquidityRates;
    mapping(address => DataTypesContract.ReserveData) _liquidityRates;

    constructor(
        address dai,
        address aDai,
        uint256 liquidityRatesDai,
        address usdc,
        address aUsdc,
        uint256 liquidityRatesUsdc,
        address usdt,
        address aUsdt,
        uint256 liquidityRatesUsdt
    ) {
        _aTokens[dai] = aDai;
        _aTokens[usdc] = aUsdc;
        _aTokens[usdt] = aUsdt;

        _liquidityRates[dai].currentLiquidityRate = liquidityRatesDai.toUint128();
        _liquidityRates[usdc].currentLiquidityRate = liquidityRatesUsdc.toUint128();
        _liquidityRates[usdt].currentLiquidityRate = liquidityRatesUsdt.toUint128();
    }

    function deposit(
        address asset,
        uint256 amount,
        address owner,
        uint16 referralCode
    ) public {
        MockIAToken aToken = MockIAToken(_aTokens[asset]);
        IERC20(asset).safeTransferFrom(owner, address(this), amount);
        aToken.mint(owner, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) public {
        MockIAToken aToken = MockIAToken(_aTokens[asset]);
        IERC20(asset).safeTransfer(to, amount);
        aToken.burn(msg.sender, amount);
    }

    function getReserveData(address asset)
        public
        view
        returns (DataTypesContract.ReserveData memory)
    {
        return _liquidityRates[asset];
    }
}
