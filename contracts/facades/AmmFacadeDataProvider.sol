// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/types/AmmStorageTypes.sol";
import "../interfaces/types/AmmFacadeTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAmmTreasurySpreadModel.sol";
import "../interfaces/IAmmTreasuryFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../amm/AmmStorage.sol";
import "../libraries/AmmLib.sol";

contract AmmTreasuryFacadeDataProvider is
    Initializable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmTreasuryFacadeDataProvider
{
    address internal _iporOracle;
    address[] internal _assets;
    mapping(address => AmmFacadeTypes.AssetConfig) internal _assetConfig;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address iporOracle,
        address[] memory assets,
        address[] memory ammTreasurys,
        address[] memory ammStorages
    ) public initializer {
        require(
            assets.length == ammTreasurys.length && assets.length == ammStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);

        __Ownable_init();
        __UUPSUpgradeable_init();
        _iporOracle = iporOracle;

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i != assetsLength; i++) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ammTreasurys[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ammStorages[i] != address(0), IporErrors.WRONG_ADDRESS);

            _assetConfig[assets[i]] = AmmFacadeTypes.AssetConfig(ammTreasurys[i], ammStorages[i]);
        }
        _assets = assets;
    }

    function getVersion() external pure override returns (uint256) {
        return 2;
    }

    function getConfiguration() external view override returns (AmmFacadeTypes.AssetConfiguration[] memory) {
        uint256 timestamp = block.timestamp;
        uint256 assetsLength = _assets.length;
        AmmFacadeTypes.AssetConfiguration[] memory config = new AmmFacadeTypes.AssetConfiguration[](assetsLength);

        for (uint256 i = 0; i != assetsLength; i++) {
            config[i] = _createIporAssetConfig(_assets[i], timestamp);
        }
        return config;
    }

    function getBalance(address asset) external view override returns (AmmFacadeTypes.Balance memory balance) {
        AmmFacadeTypes.AssetConfig memory config = _assetConfig[asset];

        IAmmStorage ammStorage = IAmmStorage(config.ammStorage);
        (balance.totalNotionalPayFixed, balance.totalNotionalReceiveFixed) = ammStorage.getTotalOutstandingNotional();

        //        IAmmTreasury ammTreasury = IAmmTreasury(config.ammTreasury);
        IporTypes.AmmBalancesMemory memory accruedBalance;
        //        = AmmLib.getAccruedBalance(
        //            address(config.ammStorage),
        //            address(IJosephInternal(config.joseph).getAssetManagement())
        //        );

        balance.totalCollateralPayFixed = accruedBalance.totalCollateralPayFixed;
        balance.totalCollateralReceiveFixed = accruedBalance.totalCollateralReceiveFixed;
        balance.liquidityPool = accruedBalance.liquidityPool;
    }

    function getIpTokenExchangeRate(address asset) external view override returns (uint256) {
        //        AmmFacadeTypes.AssetConfig memory config = _assetConfig[asset];
        //        IJoseph joseph = IJoseph(config.joseph);
        uint256 result; // = joseph.calculateExchangeRate();
        return result;
    }

    function _getIporOracle() internal view virtual returns (address) {
        return _iporOracle;
    }

    function _createIporAssetConfig(address asset, uint256 timestamp)
        internal
        view
        returns (AmmFacadeTypes.AssetConfiguration memory assetConfiguration)
    {
        //        AmmFacadeTypes.AssetConfig memory config = _assetConfig[asset];

        //        IAmmTreasury ammTreasury = IAmmTreasury(config.ammTreasury);
        //        IJosephInternal joseph = IJosephInternal(config.joseph);

        //        IAmmTreasurySpreadModel spreadModel = IAmmTreasurySpreadModel(ammTreasury.getAmmTreasurySpreadModel());
        //        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_getIporOracle()).getAccruedIndex(timestamp, asset);

        //        IporTypes.AmmBalancesMemory memory balance = AmmLib.getAccruedBalance(
        //            address(config.ammStorage),
        //            address(joseph.getAssetManagement())
        //        );

        //TODO: fix it
        uint256 maxLeveragePayFixed;
        uint256 maxLeverageReceiveFixed; // = ammTreasury.getMaxLeverage();

        uint256 maxUtilizationRatePayFixed;
        uint256 maxUtilizationRateReceiveFixed;
        //        =
        //            ammTreasury.getMaxLpUtilizationPerLegRate();

        assetConfiguration = AmmFacadeTypes.AssetConfiguration(
            asset,
            0, //TODO:fixit
            //            ammTreasury.getMinLeverage(),
            maxLeveragePayFixed,
            maxLeverageReceiveFixed,
            0, //ammTreasury.getOpeningFeeRate(), TODO: fixit
            0, // ammTreasury.getIporPublicationFee(), TODO: fixit
            0, // ammTreasury.getWadLiquidationDepositAmount(), TODO: fixit
            0, //spreadModel.calculateSpreadPayFixed(accruedIpor, balance),//TODO:fixit
            0, //spreadModel.calculateSpreadReceiveFixed(accruedIpor, balance),//TODO fixit
            0, //TODO:fixit
            //            ammTreasury.getMaxLpUtilizationRate(),
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            0, //joseph.getMaxLiquidityPoolBalance() * Constants.D18, //TODO:fixit
            0 //joseph.getMaxLpAccountContribution() * Constants.D18 //TODO:fixit
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
