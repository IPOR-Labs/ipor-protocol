// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/types/MiltonStorageTypes.sol";
import "../interfaces/types/MiltonFacadeTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IJosephInternal.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMiltonFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../amm/MiltonStorage.sol";

contract MiltonFacadeDataProvider is
    Initializable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMiltonFacadeDataProvider
{
    address internal _iporOracle;
    address[] internal _assets;
    mapping(address => MiltonFacadeTypes.AssetConfig) internal _assetConfig;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address iporOracle,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs
    ) public initializer {
        require(
            assets.length == miltons.length && assets.length == miltonStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);

        __Ownable_init();
        __UUPSUpgradeable_init();
        _iporOracle = iporOracle;

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

    function getVersion() external pure override returns (uint256) {
        return 2;
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
            config[i] = _createIporAssetConfig(_assets[i], timestamp);
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
        (balance.totalNotionalPayFixed, balance.totalNotionalReceiveFixed) = miltonStorage
            .getTotalOutstandingNotional();

        IMiltonInternal milton = IMiltonInternal(config.milton);
        IporTypes.MiltonBalancesMemory memory accruedBalance = milton.getAccruedBalance();

        balance.totalCollateralPayFixed = accruedBalance.totalCollateralPayFixed;
        balance.totalCollateralReceiveFixed = accruedBalance.totalCollateralReceiveFixed;
        balance.liquidityPool = accruedBalance.liquidityPool;
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];
        IJoseph joseph = IJoseph(config.joseph);
        uint256 result = joseph.calculateExchangeRate();
        return result;
    }

    function _getIporOracle() internal view virtual returns (address) {
        return _iporOracle;
    }

    function _createIporAssetConfig(address asset, uint256 timestamp)
        internal
        view
        returns (MiltonFacadeTypes.AssetConfiguration memory assetConfiguration)
    {
        MiltonFacadeTypes.AssetConfig memory config = _assetConfig[asset];

        IMiltonInternal milton = IMiltonInternal(config.milton);
        IJosephInternal joseph = IJosephInternal(config.joseph);

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(milton.getMiltonSpreadModel());
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_getIporOracle()).getAccruedIndex(
            timestamp,
            asset
        );

        IporTypes.MiltonBalancesMemory memory balance = milton.getAccruedBalance();

        //TODO: fix it
        uint256 maxLeveragePayFixed;
        uint256 maxLeverageReceiveFixed;// = milton.getMaxLeverage();

        uint256 maxUtilizationRatePayFixed;
        uint256 maxUtilizationRateReceiveFixed;
//        =
//            milton.getMaxLpUtilizationPerLegRate();

        assetConfiguration = MiltonFacadeTypes.AssetConfiguration(
            asset,
            0,//TODO:fixit
//            milton.getMinLeverage(),
            maxLeveragePayFixed,
            maxLeverageReceiveFixed,
            0,//milton.getOpeningFeeRate(), TODO: fixit
           0,// milton.getIporPublicationFee(), TODO: fixit
           0,// milton.getWadLiquidationDepositAmount(), TODO: fixit
            spreadModel.calculateSpreadPayFixed(accruedIpor, balance),
            spreadModel.calculateSpreadReceiveFixed(accruedIpor, balance),
        0,//TODO:fixit
//            milton.getMaxLpUtilizationRate(),
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            joseph.getMaxLiquidityPoolBalance() * Constants.D18,
            joseph.getMaxLpAccountContribution() * Constants.D18
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
