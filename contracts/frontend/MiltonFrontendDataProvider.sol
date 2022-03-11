// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";
import "../amm/Milton.sol";

//TODO: change name to DarcyDataProvider
contract MiltonFrontendDataProvider is
    IporOwnableUpgradeable,
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

    function getMySwaps(address asset, uint256 offset, uint256 chunkSize)
        external
        view
        override
        returns (uint256 totalCount, IporSwapFront[] memory swaps)
    {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            assetConfiguration.getMiltonStorage()
        );

        (uint256 totalCount, IMiltonStorage.IporSwapId[] memory swapIds) = miltonStorage.getSwapIds(
            msg.sender,
            offset,
            chunkSize
        );

        IMilton milton = IMilton(assetConfiguration.getMilton());

        IporSwapFront[] memory iporDerivatives = new IporSwapFront[](swapIds.length);
        uint256 i = 0;
        for (i; i != swapIds.length; i++) {
            IMiltonStorage.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                DataTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId.id);
                iporDerivatives[i] = _mapToIporSwapFront(
                    asset,
                    iporSwap,
                    0,
                    milton.calculateSwapPayFixedValue(iporSwap)
                );
            } else {
                DataTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(swapId.id);
                iporDerivatives[i] = _mapToIporSwapFront(
                    asset,
                    iporSwap,
                    1,
                    milton.calculateSwapReceiveFixedValue(iporSwap));
            }
        }

        return (totalCount, iporDerivatives);
    }

    function _resolveResultSetSize(
        uint256 totalSwapNumber,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (uint256)
    {
        uint256 resultSetSize;
        if (offset > totalSwapNumber) {
            resultSetSize = 0;
        } else if (offset + chunkSize < totalSwapNumber) {
            resultSetSize = chunkSize;
        } else {
            resultSetSize = totalSwapNumber - offset;
        }

        return resultSetSize;
    }

    function _mapToIporSwapFront(
        address asset,
        DataTypes.IporSwapMemory memory iporSwap,
        uint8 direction,
        int256 value
    ) internal view returns (IporSwapFront memory)
    {
        return IporSwapFront(
            iporSwap.id,
            asset,
            iporSwap.collateral,
            iporSwap.notionalAmount,
            IporMath.division(
                iporSwap.notionalAmount * Constants.D18,
                iporSwap.collateral
            ),
            direction,
            iporSwap.fixedInterestRate,
            value,
            iporSwap.startingTimestamp,
            iporSwap.endingTimestamp,
            iporSwap.liquidationDepositAmount
        );
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
        internal
        view
        returns (IporAssetConfigurationFront memory iporAssetConfigurationFront)
    {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        IMiltonStorage miltonStorage = IMiltonStorage(
            iporAssetConfiguration.getMiltonStorage()
        );
        address miltonAddr = iporAssetConfiguration.getMilton();
        IMiltonConfiguration milton = IMiltonConfiguration(miltonAddr);

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            milton.getMiltonSpreadModel()
        );

        DataTypes.AccruedIpor memory accruedIpor = IWarren(_warren)
            .getAccruedIndex(timestamp, asset);

        DataTypes.MiltonBalanceMemory memory balance = IMilton(miltonAddr)
            .getAccruedBalance();

        uint256 spreadPayFixedValue = spreadModel.calculateSpreadPayFixed(
            miltonStorage.calculateSoapPayFixed(
                accruedIpor.ibtPrice,
                timestamp
            ),
            accruedIpor,
            balance
        );

        uint256 spreadRecFixedValue = spreadModel.calculateSpreadRecFixed(
            miltonStorage.calculateSoapReceiveFixed(
                accruedIpor.ibtPrice,
                timestamp
            ),
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

    struct SwapIdDirectionPair {
        uint128 swapId;
        uint8 direction;
    }
}
