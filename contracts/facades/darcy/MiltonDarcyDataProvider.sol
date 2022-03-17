// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/types/MiltonStorageTypes.sol";
import "../../interfaces/types/DarcyTypes.sol";
import "../../interfaces/IWarren.sol";
import "../../interfaces/IMiltonConfiguration.sol";
import "../../interfaces/IMilton.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "../../interfaces/IMiltonDarcyDataProvider.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../amm/MiltonStorage.sol";

contract MiltonDarcyDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonDarcyDataProvider
{
    address internal _warren;
    address[] internal _assets;
    mapping(address => DarcyTypes.AssetConfig) internal _assetConfig;

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

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i != assetsLength; i++) {
            _assetConfig[assets[i]] = DarcyTypes.AssetConfig(miltons[i], miltonStorages[i]);
        }
        _assets = assets;
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        DarcyTypes.AssetConfig memory config = _assetConfig[asset];
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
        DarcyTypes.AssetConfig memory config = _assetConfig[asset];
        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);
        (payFixedTotalNotional, recFixedTotalNotional) = miltonStorage
            .getTotalOutstandingNotional();
    }

    function getMySwaps(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporSwapFront[] memory swaps) {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        DarcyTypes.AssetConfig memory config = _assetConfig[asset];
        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);

        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory swapIds) = miltonStorage
            .getSwapIds(msg.sender, offset, chunkSize);

        IMilton milton = IMilton(config.milton);

        IporSwapFront[] memory iporDerivatives = new IporSwapFront[](swapIds.length);
        for (uint256 i = 0; i != swapIds.length; i++) {
            MiltonStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId.id);
                iporDerivatives[i] = _mapToIporSwapFront(
                    asset,
                    iporSwap,
                    0,
                    milton.calculateSwapPayFixedValue(iporSwap)
                );
            } else {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(
                    swapId.id
                );
                iporDerivatives[i] = _mapToIporSwapFront(
                    asset,
                    iporSwap,
                    1,
                    milton.calculateSwapReceiveFixedValue(iporSwap)
                );
            }
        }

        return (totalCount, iporDerivatives);
    }

    function _mapToIporSwapFront(
        address asset,
        IporTypes.IporSwapMemory memory iporSwap,
        uint8 direction,
        int256 value
    ) internal pure returns (IporSwapFront memory) {
        return
            IporSwapFront(
                iporSwap.id,
                asset,
                iporSwap.collateral,
                iporSwap.notionalAmount,
                IporMath.division(iporSwap.notionalAmount * Constants.D18, iporSwap.collateral),
                direction,
                iporSwap.fixedInterestRate,
                value,
                iporSwap.openTimestamp,
                iporSwap.endTimestamp,
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
        uint256 assetsLength = _assets.length;
        IporAssetConfigurationFront[] memory configFront = new IporAssetConfigurationFront[](
            assetsLength
        );

        for (uint256 i = 0; i != assetsLength; i++) {
            configFront[0] = _createIporAssetConfFront(_assets[i], timestamp);
        }
        return configFront;
    }

    function _createIporAssetConfFront(address asset, uint256 timestamp)
        internal
        view
        returns (IporAssetConfigurationFront memory iporAssetConfigurationFront)
    {
        DarcyTypes.AssetConfig memory config = _assetConfig[asset];

        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);
        address miltonAddr = config.milton;

        IMiltonConfiguration milton = IMiltonConfiguration(miltonAddr);
        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(milton.getMiltonSpreadModel());
        IporTypes.AccruedIpor memory accruedIpor = IWarren(_warren).getAccruedIndex(
            timestamp,
            asset
        );

        IporTypes.MiltonBalancesMemory memory balance = IMilton(miltonAddr).getAccruedBalance();

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
            milton.getMinLeverageValue(),
            milton.getMaxLeverageValue(),
            milton.getOpeningFeePercentage(),
            milton.getIporPublicationFeeAmount(),
            milton.getLiquidationDepositAmount(),
            milton.getIncomeFeePercentage(),
            spreadPayFixedValue,
            spreadRecFixedValue
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
