// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {
    IIporConfiguration internal immutable _iporConfiguration;

    constructor(IIporConfiguration initialIporConfiguration) {
        _iporConfiguration = initialIporConfiguration;
    }

    function getIpTokenExchangeRate(address asset)
        external
        view
        override
        returns (uint256)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        IMilton milton = IMilton(assetConfiguration.getMilton());
        uint256 result = milton.calculateExchangeRate(block.timestamp);
        return result;
    }

    function getTotalOutstandingNotional(address asset)
        external
        view
        override
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        IMiltonStorage miltonStorage = IMiltonStorage(
            assetConfiguration.getMiltonStorage()
        );
        (payFixedTotalNotional, recFixedTotalNotional) = miltonStorage
            .getTotalOutstandingNotional();
    }

    function getMyPositions(address asset)
        external
        view
        override
        returns (IporDerivativeFront[] memory items)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            assetConfiguration.getMiltonStorage()
        );
        uint256[] memory userSwapPayFixedIds = miltonStorage
            .getUserSwapPayFixedIds(msg.sender);
        uint256[] memory userSwapReceiveFixedIds = miltonStorage
            .getUserSwapPayFixedIds(msg.sender);
        IporDerivativeFront[]
            memory iporDerivatives = new IporDerivativeFront[](
                userSwapPayFixedIds.length + userSwapReceiveFixedIds.length
            );
        IMilton milton = IMilton(assetConfiguration.getMilton());

        for (uint256 i = 0; i < userSwapPayFixedIds.length; i++) {
            DataTypes.MiltonDerivativeItemMemory
                memory derivativeItem = miltonStorage.getSwapPayFixedItem(
                    userSwapPayFixedIds[i]
                );
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
                IporMath.division(
                    derivativeItem.item.notionalAmount * Constants.D18,
                    derivativeItem.item.collateral
                ),
                0,
                derivativeItem.item.fixedInterestRate,
                milton.calculateSwapPayFixedValue(derivativeItem.item),
                derivativeItem.item.startingTimestamp,
                derivativeItem.item.endingTimestamp,
                derivativeItem.item.liquidationDepositAmount
            );
        }

        for (uint256 i = 0; i < userSwapReceiveFixedIds.length; i++) {
            DataTypes.MiltonDerivativeItemMemory
                memory derivativeItem = miltonStorage.getSwapReceiveFixedItem(
                    userSwapReceiveFixedIds[i]
                );
            iporDerivatives[i] = IporDerivativeFront(
                derivativeItem.item.id,
                asset,
                derivativeItem.item.collateral,
                derivativeItem.item.notionalAmount,
                IporMath.division(
                    derivativeItem.item.notionalAmount * Constants.D18,
                    derivativeItem.item.collateral
                ),
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
        address[] memory assets = _iporConfiguration.getAssets();
        IporAssetConfigurationFront[]
            memory iporAssetConfigurationsFront = new IporAssetConfigurationFront[](
                assets.length
            );

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );

        IWarren warren = IWarren(_iporConfiguration.getWarren());

        uint256 timestamp = block.timestamp;

        uint256 spreadPayFixedValue;
        uint256 spreadRecFixedValue;

        for (uint256 i = 0; i < assets.length; i++) {
            IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                    _iporConfiguration.getIporAssetConfiguration(assets[i])
                );
            IMiltonStorage miltonStorage = IMiltonStorage(
                iporAssetConfiguration.getMiltonStorage()
            );

            DataTypes.AccruedIpor memory accruedIpor = warren.getAccruedIndex(
                timestamp,
                assets[i]
            );

            try
                spreadModel.calculatePartialSpreadPayFixed(
                    miltonStorage,
                    timestamp,
                    accruedIpor
                )
            returns (uint256 _spreadPayFixedValue) {
                spreadPayFixedValue = _spreadPayFixedValue;
            } catch {
                spreadPayFixedValue = 0;
            }

            try
                spreadModel.calculatePartialSpreadRecFixed(
                    miltonStorage,
                    timestamp,
                    accruedIpor
                )
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
