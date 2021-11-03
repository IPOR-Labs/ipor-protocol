// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonSpreadStrategy.sol";
import "../interfaces/IMilton.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {

    IIporAddressesManager public immutable addressesManager;

    constructor(IIporAddressesManager _addressesManager) {
        addressesManager = _addressesManager;
    }

    function getTotalOutstandingNotional(address asset) external override view returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional) {
        IMiltonStorage miltonStorage = IMiltonStorage(addressesManager.getMiltonStorage());
        (payFixedTotalNotional, recFixedTotalNotional) = miltonStorage.getTotalOutstandingNotional(asset);
    }

    function getMyPositions() external override view returns (IporDerivativeFront[] memory items) {
        IMiltonStorage miltonStorage = IMiltonStorage(addressesManager.getMiltonStorage());
        uint256[] memory userDerivativesIds = miltonStorage.getUserDerivativeIds(msg.sender);
        IporDerivativeFront[] memory iporDerivatives = new IporDerivativeFront[](userDerivativesIds.length);
        IMilton milton = IMilton(addressesManager.getMilton());
        for (uint256 i = 0; i < userDerivativesIds.length; i++) {
            DataTypes.MiltonDerivativeItem memory derivativeItem = miltonStorage.getDerivativeItem(userDerivativesIds[i]);
            IIporConfiguration iporConfiguration = IIporConfiguration(addressesManager.getIporConfiguration(derivativeItem.item.asset));
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                derivativeItem.item.asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
                derivativeItem.item.collateralizationFactor,
                derivativeItem.item.direction,
                derivativeItem.item.indicator.fixedInterestRate,
                milton.calculatePositionValue(derivativeItem.item, iporConfiguration.getMultiplicator()),
                derivativeItem.item.startingTimestamp,
                derivativeItem.item.endingTimestamp,
                derivativeItem.item.fee.liquidationDepositAmount
            );
        }

        return iporDerivatives;
    }

    function getConfiguration() external override view returns (IporConfigurationFront memory iporConfigurationFront) {
        address[] memory assets = addressesManager.getAssets();
        //TODO: fix it
        IIporConfiguration iporConfiguration = IIporConfiguration(addressesManager.getIporConfiguration(assets[0]));
        IMiltonSpreadStrategy spreadStrategy = IMiltonSpreadStrategy(addressesManager.getMiltonSpreadStrategy());
        IporSpreadFront[] memory spreads = new IporSpreadFront[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) = spreadStrategy.calculateSpread(assets[i], block.timestamp);
            spreads[i] = IporSpreadFront(assets[i], spreadPayFixedValue, spreadRecFixedValue);
        }

        return IporConfigurationFront(
            iporConfiguration.getMinCollateralizationFactorValue(),
            iporConfiguration.getMaxCollateralizationFactorValue(),
            iporConfiguration.getOpeningFeePercentage(),
            iporConfiguration.getIporPublicationFeeAmount(),
            iporConfiguration.getLiquidationDepositAmount(),
            iporConfiguration.getIncomeTaxPercentage(),
            spreads
        );
    }
}
