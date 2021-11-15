// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonSpreadStrategy.sol";
import "../interfaces/IMilton.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {

    IIporConfiguration public immutable addressesManager;

    constructor(IIporConfiguration _iporConfiguration) {
        addressesManager = _iporConfiguration;
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
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                derivativeItem.item.asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
                derivativeItem.item.collateralizationFactor,
                derivativeItem.item.direction,
                derivativeItem.item.indicator.fixedInterestRate,
                milton.calculatePositionValue(derivativeItem.item),
                derivativeItem.item.startingTimestamp,
                derivativeItem.item.endingTimestamp,
                derivativeItem.item.fee.liquidationDepositAmount,
                derivativeItem.item.multiplicator
            );
        }

        return iporDerivatives;
    }

    function getConfiguration() external override view returns (IporAssetConfigurationFront[] memory) {
        address[] memory assets = addressesManager.getAssets();
        IporAssetConfigurationFront[] memory iporAssetConfigurationsFront = new IporAssetConfigurationFront[](assets.length);

        IMiltonSpreadStrategy spreadStrategy = IMiltonSpreadStrategy(addressesManager.getMiltonSpreadStrategy());

        for (uint256 i = 0; i < assets.length; i++) {
            (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) = spreadStrategy.calculateSpread(assets[i], block.timestamp);
            IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(addressesManager.getIporAssetConfiguration(assets[i]));

            iporAssetConfigurationsFront[i] = IporAssetConfigurationFront(
                assets[i],
                    iporAssetConfiguration.getMinCollateralizationFactorValue(),
                    iporAssetConfiguration.getMaxCollateralizationFactorValue(),
                    iporAssetConfiguration.getOpeningFeePercentage(),
                    iporAssetConfiguration.getIporPublicationFeeAmount(),
                    iporAssetConfiguration.getLiquidationDepositAmount(),
                    iporAssetConfiguration.getIncomeTaxPercentage(),
                spreadPayFixedValue,
                spreadRecFixedValue
            );
        }
        return iporAssetConfigurationsFront;
    }
}
