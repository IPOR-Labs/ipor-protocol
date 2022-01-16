// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMilton.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {
    IIporConfiguration public immutable iporConfiguration;

    constructor(IIporConfiguration initialIporConfiguration) {
        iporConfiguration = initialIporConfiguration;
    }

    function getIpTokenExchangeRate(address asset)
        external
        view
        override
        returns (uint256)
    {
        IMilton milton = IMilton(iporConfiguration.getMilton());
        uint256 result = milton.calculateExchangeRate(asset, block.timestamp);
        return result;
    }

    function getTotalOutstandingNotional(address asset)
        external
        view
        override
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional)
    {
        IMiltonStorage miltonStorage = IMiltonStorage(
            iporConfiguration.getMiltonStorage()
        );
        (payFixedTotalNotional, recFixedTotalNotional) = miltonStorage
            .getTotalOutstandingNotional(asset);
    }

    function getMyPositions()
        external
        view
        override
        returns (IporDerivativeFront[] memory items)
    {
        IMiltonStorage miltonStorage = IMiltonStorage(
            iporConfiguration.getMiltonStorage()
        );
        uint256[] memory userSwapPayFixedIds = miltonStorage
            .getUserSwapPayFixedIds(msg.sender);
		uint256[] memory userSwapReceiveFixedIds = miltonStorage
            .getUserSwapPayFixedIds(msg.sender);
        IporDerivativeFront[]
            memory iporDerivatives = new IporDerivativeFront[](
                userSwapPayFixedIds.length + userSwapReceiveFixedIds.length
            );
        IMilton milton = IMilton(iporConfiguration.getMilton());

        for (uint256 i = 0; i < userSwapPayFixedIds.length; i++) {
            DataTypes.MiltonDerivativeItemMemory memory derivativeItem = miltonStorage
                .getSwapPayFixedItem(userSwapPayFixedIds[i]);
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                derivativeItem.item.asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
				IporMath.division(derivativeItem.item.notionalAmount * Constants.D18, derivativeItem.item.collateral),
                0,
                derivativeItem.item.fixedInterestRate,
                milton.calculateSwapPayFixedValue(derivativeItem.item),
                derivativeItem.item.startingTimestamp,
                derivativeItem.item.endingTimestamp,
                derivativeItem.item.liquidationDepositAmount
            );
        }

		for (uint256 i = 0; i < userSwapReceiveFixedIds.length; i++) {
            DataTypes.MiltonDerivativeItemMemory memory derivativeItem = miltonStorage
                .getSwapReceiveFixedItem(userSwapReceiveFixedIds[i]);
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                derivativeItem.item.asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
				IporMath.division(derivativeItem.item.notionalAmount * Constants.D18, derivativeItem.item.collateral),
                1,
                derivativeItem.item.fixedInterestRate,
                milton.calculateSwapReceiveFixedValue(derivativeItem.item),
                derivativeItem.item.startingTimestamp,
                derivativeItem.item.endingTimestamp,
                derivativeItem.item.liquidationDepositAmount
            );
        }

        return iporDerivatives;
    }

    function getConfiguration()
        external
        view
        override
        returns (IporAssetConfigurationFront[] memory)
    {
        address[] memory assets = iporConfiguration.getAssets();
        IporAssetConfigurationFront[]
            memory iporAssetConfigurationsFront = new IporAssetConfigurationFront[](
                assets.length
            );

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            iporConfiguration.getMiltonSpreadModel()
        );

        uint256 timestamp = block.timestamp;


		uint256 spreadPayFixedValue;
		uint256 spreadRecFixedValue;

        for (uint256 i = 0; i < assets.length; i++) {
            IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                    iporConfiguration.getIporAssetConfiguration(assets[i])
               );

            try
                spreadModel.calculatePartialSpreadPayFixed(timestamp, assets[i])
            returns (uint256 _spreadPayFixedValue) {
                spreadPayFixedValue = _spreadPayFixedValue;
            } catch {
                spreadPayFixedValue = 0;
            }

            try
                spreadModel.calculatePartialSpreadRecFixed(timestamp, assets[i])
            returns (uint256 _spreadRecFixedValue) {
                spreadRecFixedValue = _spreadRecFixedValue;
            } catch {
                spreadRecFixedValue = 0;
            }

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
