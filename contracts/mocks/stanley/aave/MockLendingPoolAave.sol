//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../vault/interfaces/aave/DataTypesContract.sol";
import "../../../vault/interfaces/aave/AaveLendingPoolV2.sol";
import "./aTokens/MockIAToken.sol";

contract MockLendingPoolAave is AaveLendingPoolV2 {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    // asset(dai/usdt/usdc) => adai/ausdt/ausdc
    mapping(address => address) _aTokens;
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
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI asset address cannot be 0"));
        require(aDai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " aDAI asset address cannot be 0"));
        require(usdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC asset address cannot be 0"));
        require(aUsdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " aUSDC asset address cannot be 0"));
        require(usdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT asset address cannot be 0"));
        require(aUsdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " aUSDT asset address cannot be 0"));

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
    ) external {
        require(referralCode < type(uint16).max);
        MockIAToken aToken = MockIAToken(_aTokens[asset]);
        IERC20(asset).safeTransferFrom(owner, address(this), amount);
        aToken.mint(owner, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        MockIAToken aToken = MockIAToken(_aTokens[asset]);
        IERC20(asset).safeTransfer(to, amount);
        aToken.burn(msg.sender, amount);
        return amount;
    }

    function getReserveData(address asset) external view returns (DataTypesContract.ReserveData memory) {
        return _liquidityRates[asset];
    }
}
