// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/types/AmmTypes.sol";
import "../interfaces/types/AmmStorageTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAssetManagement.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "./Constants.sol";
import "./math/IporMath.sol";
import "./errors/IporErrors.sol";
import "./errors/AmmErrors.sol";
import "../amm/libraries/SoapIndicatorLogic.sol";

/// @title AMM basic logic library
library AmmLib {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SoapIndicatorLogic for AmmStorageTypes.SoapIndicators;

    /// @notice Gets AMM exchange rate
    /// @param model AMM model skeleton of the pool
    /// @return AMM exchange rate
    function getExchangeRate(AmmTypes.AmmPoolCoreModel memory model) internal view returns (uint256) {
        (, , int256 soap) = getSoap(model);

        uint256 liquidityPoolBalance = getAccruedBalance(model).liquidityPool;

        int256 balance = liquidityPoolBalance.toInt256() - soap;

        require(balance >= 0, AmmErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = IIpToken(model.ipToken).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

    /// @notice Gets AMM exchange rate
    /// @param model AMM model skeleton of the pool
    /// @param liquidityPoolBalance liquidity pool balance
    /// @return AMM exchange rate
    /// @dev For gas optimization with additional param liquidityPoolBalance with already calculated value
    function getExchangeRate(
        AmmTypes.AmmPoolCoreModel memory model,
        uint256 liquidityPoolBalance
    ) internal view returns (uint256) {
        (, , int256 soap) = getSoap(model);

        int256 balance = liquidityPoolBalance.toInt256() - soap;
        require(balance >= 0, AmmErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = IIpToken(model.ipToken).totalSupply();
        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

    /// @notice Gets AMM SOAP Sum Of All Payouts
    /// @param model AMM model skeleton of the pool
    /// @return soapPayFixed SOAP Pay Fixed
    /// @return soapReceiveFixed SOAP Receive Fixed
    /// @return soap SOAP Sum Of All Payouts
    function getSoap(
        AmmTypes.AmmPoolCoreModel memory model
    ) internal view returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        uint256 timestamp = block.timestamp;
        (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        ) = IAmmStorage(model.ammStorage).getSoapIndicators();

        uint256 ibtPrice = IIporOracle(model.iporOracle).calculateAccruedIbtPrice(model.asset, timestamp);
        soapPayFixed = indicatorsPayFixed.calculateSoapPayFixed(timestamp, ibtPrice);
        soapReceiveFixed = indicatorsReceiveFixed.calculateSoapReceiveFixed(timestamp, ibtPrice);
        soap = soapPayFixed + soapReceiveFixed;
    }

    /// @notice Gets accrued balance of the pool
    /// @param model AMM model skeleton of the pool
    /// @return accrued balance of the pool
    /// @dev balance takes into consideration asset management vault balance and their accrued interest
    function getAccruedBalance(
        AmmTypes.AmmPoolCoreModel memory model
    ) internal view returns (IporTypes.AmmBalancesMemory memory) {
        require(model.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammTreasury"));
        IporTypes.AmmBalancesMemory memory accruedBalance = IAmmStorage(model.ammStorage).getBalance();

        uint256 actualVaultBalance = IAssetManagement(model.assetManagement).totalBalance();
        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, AmmErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();
        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }

    function _leverageInRange(uint256 leverage, uint256 cfgMinLeverage) internal pure returns (uint256) {
        if (leverage > Constants.WAD_LEVERAGE_1000) {
            return Constants.WAD_LEVERAGE_1000;
        } else if (leverage < cfgMinLeverage) {
            return cfgMinLeverage;
        } else {
            return leverage;
        }
    }
}
