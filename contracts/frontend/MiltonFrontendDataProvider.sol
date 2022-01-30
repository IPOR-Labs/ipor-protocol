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

    function getMySwaps(address asset)
        external
        view
        override
        returns (IporSwapFront[] memory items)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            assetConfiguration.getMiltonStorage()
        );
        uint128[] memory accountSwapPayFixedIds = miltonStorage
            .getSwapPayFixedIds(msg.sender);

        uint128[] memory accountSwapReceiveFixedIds = miltonStorage
            .getSwapReceiveFixedIds(msg.sender);

        uint256 pfSwapsLength = accountSwapPayFixedIds.length;

        uint256 swapsLength = pfSwapsLength + accountSwapReceiveFixedIds.length;
        IporSwapFront[] memory iporDerivatives = new IporSwapFront[](
            swapsLength
        );
        IMilton milton = IMilton(assetConfiguration.getMilton());
        uint256 i = 0;

        for (i; i != pfSwapsLength; i++) {
            DataTypes.IporSwapMemory memory iporSwap = miltonStorage
                .getSwapPayFixed(accountSwapPayFixedIds[i]);
            iporDerivatives[i] = IporSwapFront(
                iporSwap.id,
                asset,
                iporSwap.collateral,
                iporSwap.notionalAmount,
                IporMath.division(
                    iporSwap.notionalAmount * Constants.D18,
                    iporSwap.collateral
                ),
                0,
                iporSwap.fixedInterestRate,
                milton.calculateSwapPayFixedValue(iporSwap),
                iporSwap.startingTimestamp,
                iporSwap.endingTimestamp,
                iporSwap.liquidationDepositAmount
            );
        }

        i = pfSwapsLength;

        for (i; i != swapsLength; i++) {
            DataTypes.IporSwapMemory memory iporSwap = miltonStorage
                .getSwapReceiveFixed(
                    accountSwapReceiveFixedIds[i - pfSwapsLength]
                );
            iporDerivatives[i] = IporSwapFront(
                iporSwap.id,
                asset,
                iporSwap.collateral,
                iporSwap.notionalAmount,
                IporMath.division(
                    iporSwap.notionalAmount * Constants.D18,
                    iporSwap.collateral
                ),
                1,
                iporSwap.fixedInterestRate,
                milton.calculateSwapReceiveFixedValue(iporSwap),
                iporSwap.startingTimestamp,
                iporSwap.endingTimestamp,
                iporSwap.liquidationDepositAmount
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
        uint256 i = 0;
        for (i; i != assets.length; i++) {
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
