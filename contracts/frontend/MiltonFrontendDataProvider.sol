// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";

//TODO: change name to DarcyDataProvider
contract MiltonFrontendDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonFrontendDataProvider
{
    address internal _warren;
    address[] internal _assets;
    mapping(address => AssetConfig) internal _assetConfig;

    function initialize(
        address warren,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages
    ) public initializer {
        require(
            assets.length == miltons.length && assets.length == miltonStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        __Ownable_init();
        _warren = warren;

        uint256 i = 0;
        for (i; i != assets.length; i++) {
            _assetConfig[assets[i]] = AssetConfig(miltons[i], miltonStorages[i]);
        }
        _assets = assets;
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        AssetConfig memory config = _assetConfig[asset];
        IMilton milton = IMilton(config.milton);
        uint256 result = milton.calculateExchangeRate(block.timestamp);
        return result;
    }

    function getTotalOutstandingNotional(address asset)
        external
        view
        override
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional)
    {
        AssetConfig memory config = _assetConfig[asset];
        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);
        (payFixedTotalNotional, recFixedTotalNotional) = miltonStorage
            .getTotalOutstandingNotional();
    }

    function getMySwaps(address asset)
        external
        view
        override
        returns (IporSwapFront[] memory items)
    {
        AssetConfig memory config = _assetConfig[asset];
        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);

        uint128[] memory accountSwapPayFixedIds = miltonStorage.getSwapPayFixedIds(msg.sender);
        uint128[] memory accountSwapReceiveFixedIds = miltonStorage.getSwapReceiveFixedIds(
            msg.sender
        );

        uint256 pfSwapsLength = accountSwapPayFixedIds.length;

        uint256 swapsLength = pfSwapsLength + accountSwapReceiveFixedIds.length;
        IporSwapFront[] memory iporDerivatives = new IporSwapFront[](swapsLength);
        IMilton milton = IMilton(config.milton);

        uint256 i = 0;
        for (i; i != pfSwapsLength; i++) {
            DataTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(
                accountSwapPayFixedIds[i]
            );
            iporDerivatives[i] = IporSwapFront(
                iporSwap.id,
                asset,
                iporSwap.collateral,
                iporSwap.notionalAmount,
                IporMath.division(iporSwap.notionalAmount * Constants.D18, iporSwap.collateral),
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
            DataTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(
                accountSwapReceiveFixedIds[i - pfSwapsLength]
            );
            iporDerivatives[i] = IporSwapFront(
                iporSwap.id,
                asset,
                iporSwap.collateral,
                iporSwap.notionalAmount,
                IporMath.division(iporSwap.notionalAmount * Constants.D18, iporSwap.collateral),
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
        uint256 assetsLength = _assets.length;
        IporAssetConfigurationFront[] memory configFront = new IporAssetConfigurationFront[](
            assetsLength
        );

        uint256 i = 0;
        for (i; i != assetsLength; i++) {
            configFront[0] = _createIporAssetConfFront(_assets[i], timestamp);
        }
        return configFront;
    }

    function _createIporAssetConfFront(address asset, uint256 timestamp)
        internal
        view
        returns (IporAssetConfigurationFront memory iporAssetConfigurationFront)
    {
        AssetConfig memory config = _assetConfig[asset];

        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);
        address miltonAddr = config.milton;

        IMiltonConfiguration milton = IMiltonConfiguration(miltonAddr);
        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(milton.getMiltonSpreadModel());
        DataTypes.AccruedIpor memory accruedIpor = IWarren(_warren).getAccruedIndex(
            timestamp,
            asset
        );

        DataTypes.MiltonBalanceMemory memory balance = IMilton(miltonAddr).getAccruedBalance();

        uint256 spreadPayFixedValue = spreadModel.calculateSpreadPayFixed(
            miltonStorage.calculateSoapPayFixed(accruedIpor.ibtPrice, timestamp),
            accruedIpor,
            balance
        );

        uint256 spreadRecFixedValue = spreadModel.calculateSpreadRecFixed(
            miltonStorage.calculateSoapReceiveFixed(accruedIpor.ibtPrice, timestamp),
            accruedIpor,
            balance
        );

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

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
