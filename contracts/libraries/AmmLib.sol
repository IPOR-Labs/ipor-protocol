// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IIporOracle.sol";

library AmmLib {
    using SafeCast for uint256;
    using SafeCast for int256;

    function getSOAP(address asset, address ammStorage, address iporOracle)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (soapPayFixed, soapReceiveFixed, soap) = IMiltonStorage(ammStorage).calculateSoap(
            IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp),
            block.timestamp
        );
    }

    function getAccruedBalance(address ammStorage, address assetManagement)
        internal
        view
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        IporTypes.MiltonBalancesMemory memory accruedBalance = IMiltonStorage(ammStorage).getBalance();

        uint256 actualVaultBalance = IStanley(assetManagement).totalBalance(address(this));

        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, MiltonErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();

        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }
}
