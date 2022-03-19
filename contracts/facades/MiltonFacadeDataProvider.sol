// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/types/MiltonStorageTypes.sol";
import "../interfaces/types/MiltonFacadeTypes.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMiltonFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFacadeDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonFacadeDataProvider
{
    address internal _warren;
    address[] internal _assets;
    mapping(address => MiltonFacadeTypes.AssetConfig) internal _assetConfig;

    function initialize(
        address warren,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs
    ) public initializer {
        require(
            assets.length == miltons.length && assets.length == miltonStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        __Ownable_init();
        _warren = warren;

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i != assetsLength; i++) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(miltons[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(miltonStorages[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(josephs[i] != address(0), IporErrors.WRONG_ADDRESS);

            _assetConfig[assets[i]] = MiltonFacadeTypes.AssetConfig(
                miltons[i],
                miltonStorages[i],
                josephs[i]
            );
        }
        _assets = assets;
    }

    function getConfiguration()
        external
        view
        override
        returns (MiltonFacadeTypes.AssetConfiguration[] memory)
    {
        uint256 timestamp = block.timestamp;
        uint256 assetsLength = _assets.length;
        MiltonFacadeTypes.AssetConfiguration[]
            memory config = new MiltonFacadeTypes.AssetConfiguration[](assetsLength);

        for (uint256 i = 0; i != assetsLength; i++) {
            config[0] = _createIporAssetConfig(_assets[i], timestamp);
        }
        return config;
    }

    function getBalance(address asset)
        external
        view
        override
        returns (MiltonFacadeTypes.Balance memory balance)
    {
        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];

        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);
        (balance.payFixedTotalNotional, balance.recFixedTotalNotional) = miltonStorage
            .getTotalOutstandingNotional();

        IMilton milton = IMilton(config.milton);
        IporTypes.MiltonBalancesMemory memory accruedBalance = milton.getAccruedBalance();

        balance.payFixedTotalCollateral = accruedBalance.payFixedSwaps;
        balance.recFixedTotalCollateral = accruedBalance.receiveFixedSwaps;
        balance.liquidityPool = accruedBalance.liquidityPool;
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];
        IJoseph joseph = IJoseph(config.joseph);
        uint256 result = joseph.calculateExchangeRate();
        return result;
    }

    function getMySwaps(
        address asset,
        uint256 offset,
        uint256 chunkSize
    )
        external
        view
        override
        returns (uint256 totalCount, MiltonFacadeTypes.IporSwap[] memory swaps)
    {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];
        IMiltonStorage miltonStorage = IMiltonStorage(config.miltonStorage);

        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory swapIds) = miltonStorage
            .getSwapIds(msg.sender, offset, chunkSize);

        IMilton milton = IMilton(config.milton);

        MiltonFacadeTypes.IporSwap[] memory iporDerivatives = new MiltonFacadeTypes.IporSwap[](
            swapIds.length
        );
        for (uint256 i = 0; i != swapIds.length; i++) {
            MiltonStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId.id);
                iporDerivatives[i] = _mapToIporSwap(
                    asset,
                    iporSwap,
                    0,
                    milton.calculateSwapPayFixedValue(iporSwap)
                );
            } else {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(
                    swapId.id
                );
                iporDerivatives[i] = _mapToIporSwap(
                    asset,
                    iporSwap,
                    1,
                    milton.calculateSwapReceiveFixedValue(iporSwap)
                );
            }
        }

        return (totalCount, iporDerivatives);
    }

    function _mapToIporSwap(
        address asset,
        IporTypes.IporSwapMemory memory iporSwap,
        uint8 direction,
        int256 value
    ) internal pure returns (MiltonFacadeTypes.IporSwap memory) {
        return
            MiltonFacadeTypes.IporSwap(
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

    function _createIporAssetConfig(address asset, uint256 timestamp)
        internal
        view
        returns (MiltonFacadeTypes.AssetConfiguration memory assetConfiguration)
    {
        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];

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

        assetConfiguration = MiltonFacadeTypes.AssetConfiguration(
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
