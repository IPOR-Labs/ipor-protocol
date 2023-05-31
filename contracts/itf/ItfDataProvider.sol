// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/types/IporTypes.sol";
import "./types/ItfDataProviderTypes.sol";
import "../amm/AmmStorage.sol";
import "./ItfIporOracle.sol";
import "../interfaces/IAmmTreasurySpreadInternal.sol";

contract ItfDataProvider is Initializable, UUPSUpgradeable, IporOwnableUpgradeable {
    mapping(address => AmmStorage) private _ammStorages;
    ItfIporOracle private _iporOracle;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // all arrary contains adresses for 1) usdt, 2) usdc, 3) dai
    function initialize(
        address[] memory assets,
        address[] memory ammStorages,
        address iporOracle
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        uint256 i = 0;
        for (i; i < assets.length; ) {
            _ammStorages[assets[i]] = AmmStorage(ammStorages[i]);
            unchecked {
                ++i;
            }
        }
        _iporOracle = ItfIporOracle(iporOracle);
    }

    function getAmmData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfAmmData memory ammData)
    {
        ammData = ItfDataProviderTypes.ItfAmmData(
            block.number,
            timestamp,
            asset,
            getIporOracleData(timestamp, asset),
            getAmmStorageData(asset)
        );
    }

    function getIporOracleData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfIporOracleData memory iporOracleData)
    {
        (uint256 indexValue, uint256 ibtPrice, uint256 lastUpdateTimestamp) = _iporOracle.getIndex(asset);
        IporTypes.AccruedIpor memory accruedIndex = _iporOracle.getAccruedIndex(timestamp, asset);

        iporOracleData = ItfDataProviderTypes.ItfIporOracleData(
            indexValue,
            ibtPrice,
            lastUpdateTimestamp,
            accruedIndex.indexValue,
            accruedIndex.ibtPrice,
            accruedIndex.exponentialMovingAverage,
            accruedIndex.exponentialWeightedMovingVariance
        );
    }

    function getAmmStorageData(address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfAmmStorageData memory ammStorageData)
    {
        AmmStorage ammStorage = _ammStorages[asset];
        AmmStorageTypes.ExtendedBalancesMemory memory balance = ammStorage.getExtendedBalance();
        (uint256 totalNotionalPayFixed, uint256 totalNotionalReceiveFixed) = ammStorage.getTotalOutstandingNotional();
        ammStorageData = ItfDataProviderTypes.ItfAmmStorageData(
            balance.totalCollateralPayFixed,
            balance.totalCollateralReceiveFixed,
            balance.liquidityPool,
            balance.vault,
            balance.iporPublicationFee,
            balance.treasury,
            totalNotionalPayFixed,
            totalNotionalReceiveFixed
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
