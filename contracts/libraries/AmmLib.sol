// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "contracts/libraries/Constants.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/amm/libraries/SoapIndicatorLogic.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "contracts/interfaces/IIpToken.sol";
import "contracts/interfaces/IIporOracle.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/interfaces/IAssetManagement.sol";

library AmmLib {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SoapIndicatorLogic for AmmStorageTypes.SoapIndicators;

    function getExchangeRate(AmmTypes.AmmPoolCoreModel memory model) internal view returns (uint256) {
        (, , int256 soap) = getSOAP(model);

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

    /// @dev For gas optimization with additional param liquidityPoolBalance with already calculated value
    function getExchangeRate(AmmTypes.AmmPoolCoreModel memory model, uint256 liquidityPoolBalance)
        internal
        view
        returns (uint256)
    {
        (, , int256 soap) = getSOAP(model);

        int256 balance = liquidityPoolBalance.toInt256() - soap;

        require(balance >= 0, AmmErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = IIpToken(model.ipToken).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

    function getSOAP(AmmTypes.AmmPoolCoreModel memory model)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
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

    function getAccruedBalance(AmmTypes.AmmPoolCoreModel memory model)
        internal
        view
        returns (IporTypes.AmmBalancesMemory memory)
    {
        require(model.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " ammTreasury"));
        IporTypes.AmmBalancesMemory memory accruedBalance = IAmmStorage(model.ammStorage).getBalance();

        uint256 actualVaultBalance = IAssetManagement(model.assetManagement).totalBalance(model.ammTreasury);

        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, AmmErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();

        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }
}
