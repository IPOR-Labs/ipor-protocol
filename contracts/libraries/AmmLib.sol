// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IStanley.sol";

library AmmLib {
    using SafeCast for uint256;
    using SafeCast for int256;

    function getExchangeRate(AmmTypes.AmmPoolCoreModel memory model) internal view returns (uint256) {
        (, , int256 soap) = getSOAP(model);

        uint256 liquidityPoolBalance = getAccruedBalance(model).liquidityPool;

        int256 balance = liquidityPoolBalance.toInt256() - soap;

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = IIpToken(model.ipToken).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
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

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = IIpToken(model.ipToken).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
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
        (soapPayFixed, soapReceiveFixed, soap) = IMiltonStorage(model.ammStorage).calculateSoap(
            IIporOracle(model.iporOracle).calculateAccruedIbtPrice(model.asset, block.timestamp),
            block.timestamp
        );
    }

    function getAccruedBalance(AmmTypes.AmmPoolCoreModel memory model)
        internal
        view
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        IporTypes.MiltonBalancesMemory memory accruedBalance = IMiltonStorage(model.ammStorage).getBalance();

        uint256 actualVaultBalance = IStanley(model.assetManagement).totalBalance(address(this));

        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, MiltonErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();

        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }
}
