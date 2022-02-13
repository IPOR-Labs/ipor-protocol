// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFrontendDataProvider is
    OwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonFrontendDataProvider
{
    IIporConfiguration internal _iporConfiguration;
	address internal _warren;
    address internal _assetDai;
    address internal _assetUsdc;
    address internal _assetUsdt;

    function initialize(
        IIporConfiguration iporConfiguration,
		address warren,
        address assetDai,
        address assetUsdt,
        address assetUsdc
    ) public initializer {
        __Ownable_init();
        _iporConfiguration = iporConfiguration;
		_warren = warren;
        _assetDai = assetDai;
        _assetUsdc = assetUsdc;
        _assetUsdt = assetUsdt;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

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
        uint256 timestamp = block.timestamp;

        IporAssetConfigurationFront[]
            memory iporAssetConfigurationsFront = new IporAssetConfigurationFront[](
                3
            );

        iporAssetConfigurationsFront[0] = _createIporAssetConfFront(
            _assetDai,
            timestamp
        );
        iporAssetConfigurationsFront[1] = _createIporAssetConfFront(
            _assetUsdt,
            timestamp
        );
        iporAssetConfigurationsFront[2] = _createIporAssetConfFront(
            _assetUsdc,
            timestamp
        );
        return iporAssetConfigurationsFront;
    }

    function _createIporAssetConfFront(address asset, uint256 timestamp)
        internal view 
        returns (IporAssetConfigurationFront memory iporAssetConfigurationFront)
    {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        IMiltonStorage miltonStorage = IMiltonStorage(
            iporAssetConfiguration.getMiltonStorage()
        );
        IMiltonConfiguration milton = IMiltonConfiguration(
            iporAssetConfiguration.getMilton()
        );

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            milton.getMiltonSpreadModel()
        );

        DataTypes.AccruedIpor memory accruedIpor = IWarren(_warren).getAccruedIndex(
            timestamp,
            asset
        );

		uint256 spreadPayFixedValue;
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

		uint256 spreadRecFixedValue;
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

        iporAssetConfigurationFront = IporAssetConfigurationFront(
            asset,
            milton.getMinCollateralizationFactorValue(),
            milton.getMaxCollateralizationFactorValue(),
            milton.getOpeningFeePercentage(),
            milton.getIporPublicationFeeAmount(),
            milton.getLiquidationDepositAmount(),
            milton.getIncomeTaxPercentage(),
            spreadPayFixedValue,
            spreadRecFixedValue
        );
    }
}
