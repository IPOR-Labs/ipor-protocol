// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/IporOracleTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IProxyImplementation.sol";
import "../interfaces/IIporContractCommonGov.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/IporOracleErrors.sol";
import "../libraries/math/InterestRates.sol";
import "../security/PauseManager.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/IporLogic.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract IporOracle is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IIporOracle,
    IProxyImplementation,
    IIporContractCommonGov
{
    using SafeCast for uint256;
    using IporLogic for IporOracleTypes.IPOR;

    address internal immutable _usdt;
    uint256 internal immutable _usdtInitialIbtPrice;
    address internal immutable _usdc;
    uint256 internal immutable _usdcInitialIbtPrice;
    address internal immutable _dai;
    uint256 internal immutable _daiInitialIbtPrice;

    mapping(address => uint256) internal _updaters;
    mapping(address => IporOracleTypes.IPOR) internal _indexes;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_PAUSE_GUARDIAN);
        _;
    }

    modifier onlyUpdater() {
        require(_updaters[msg.sender] == 1, IporOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address usdt,
        uint256 usdtInitialIbtPrice,
        address usdc,
        uint256 usdcInitialIbtPrice,
        address dai,
        uint256 daiInitialIbtPrice
    ) {
        if (usdt == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, usdt, "constructor USDT");
        }
        if (usdc == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, usdc, "constructor USDC");
        }
        if (dai == address(0)) {
            revert IporErrors.WrongAddress(IporErrors.WRONG_ADDRESS, dai, "constructor DAI");
        }

        _usdt = usdt;
        _usdtInitialIbtPrice = usdtInitialIbtPrice;
        _usdc = usdc;
        _usdcInitialIbtPrice = usdcInitialIbtPrice;
        _dai = dai;
        _daiInitialIbtPrice = daiInitialIbtPrice;
        _disableInitializers();
    }

    function initialize(address[] memory assets, uint32[] memory updateTimestamps) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        require(assetsLength == updateTimestamps.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);

        for (uint256 i; i != assetsLength; ) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indexes[assets[i]] = IporOracleTypes.IPOR(0, 0, updateTimestamps[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_002;
    }

    function getConfiguration()
        external
        view
        returns (
            address usdt,
            uint256 usdtInitialIbtPrice,
            address usdc,
            uint256 usdcInitialIbtPrice,
            address dai,
            uint256 daiInitialIbtPrice
        )
    {
        return (_usdt, _usdtInitialIbtPrice, _usdc, _usdcInitialIbtPrice, _dai, _daiInitialIbtPrice);
    }

    function getIndex(
        address asset
    ) external view override returns (uint256 indexValue, uint256 ibtPrice, uint256 lastUpdateTimestamp) {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            indexValue = ipor.indexValue,
            ibtPrice = _calculateAccruedIbtPrice(asset, ipor, ipor.lastUpdateTimestamp),
            lastUpdateTimestamp = ipor.lastUpdateTimestamp
        );
    }

    function getAccruedIndex(
        uint256 calculateTimestamp,
        address asset
    ) external view virtual override returns (IporTypes.AccruedIpor memory accruedIpor) {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        accruedIpor = IporTypes.AccruedIpor(
            ipor.indexValue,
            _calculateAccruedIbtPrice(asset, ipor, calculateTimestamp)
        );
    }

    function calculateAccruedIbtPrice(
        address asset,
        uint256 calculateTimestamp
    ) external view override returns (uint256) {
        return _calculateAccruedIbtPrice(asset, _indexes[asset], calculateTimestamp);
    }

    function updateIndexes(
        IIporOracle.UpdateIndexParams[] calldata indexesToUpdate
    ) external override onlyUpdater whenNotPaused {
        uint256 length = indexesToUpdate.length;
        for (uint256 i; i < length; ) {
            _updateIndex(indexesToUpdate[i].asset, indexesToUpdate[i].indexValue, block.timestamp);
            unchecked {
                ++i;
            }
        }
    }

    function updateIndexesAndQuasiIbtPrice(
        IIporOracle.UpdateIndexParams[] calldata indexesToUpdate
    ) external override onlyUpdater whenNotPaused {
        uint256 length = indexesToUpdate.length;
        for (uint256 i; i < length; ) {
            _updateIndexAndQuasiIbtPrice(
                indexesToUpdate[i].asset,
                indexesToUpdate[i].indexValue,
                indexesToUpdate[i].updateTimestamp,
                indexesToUpdate[i].quasiIbtPrice
            );
            unchecked {
                ++i;
            }
        }
    }

    function _updateIndexAndQuasiIbtPrice(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp,
        uint256 newQuasiIbtPrice
    ) internal {
        IporOracleTypes.IPOR memory oldIpor = _indexes[asset];
        if (oldIpor.lastUpdateTimestamp == 0) {
            revert IporOracleErrors.UpdateIndex(
                asset,
                IporOracleErrors.ASSET_NOT_SUPPORTED,
                "updateIndexAndQuasiIbtPrice"
            );
        }
        if (oldIpor.lastUpdateTimestamp > updateTimestamp || updateTimestamp >= block.timestamp) {
            revert IporOracleErrors.UpdateIndex(
                asset,
                IporOracleErrors.WRONG_INDEX_TIMESTAMP,
                "updateIndexAndQuasiIbtPrice"
            );
        }

        _indexes[asset] = IporOracleTypes.IPOR(
            newQuasiIbtPrice.toUint128(),
            indexValue.toUint64(),
            updateTimestamp.toUint32()
        );

        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    function addUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 1;
        emit IporIndexAddUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 0;
        emit IporIndexRemoveUpdater(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function addAsset(address asset, uint256 updateTimestamp) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indexes[asset].quasiIbtPrice == 0, IporOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS);
        _indexes[asset] = IporOracleTypes.IPOR(0, 0, updateTimestamp.toUint32());
        emit IporIndexAddAsset(asset, updateTimestamp);
    }

    function removeAsset(address asset) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indexes[asset].lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        delete _indexes[asset];
        emit IporIndexRemoveAsset(asset);
    }

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indexes[asset].lastUpdateTimestamp > 0;
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _updateIndex(address asset, uint256 indexValue, uint256 updateTimestamp) internal {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];

        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        require(
            ipor.lastUpdateTimestamp <= updateTimestamp,
            IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );

        uint256 newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(updateTimestamp);

        _indexes[asset] = IporOracleTypes.IPOR(
            newQuasiIbtPrice.toUint128(),
            indexValue.toUint64(),
            updateTimestamp.toUint32()
        );

        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    function _calculateAccruedIbtPrice(
        address asset,
        IporOracleTypes.IPOR memory ipor,
        uint256 calculateTimestamp
    ) internal view returns (uint256) {
        uint256 initialIbtPrice = _getInitialIbtPrice(asset);
        uint256 interestRateMultipliedByTime = ipor.accrueQuasiIbtPrice(calculateTimestamp);
        return
            InterestRates.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                initialIbtPrice,
                interestRateMultipliedByTime
            );
    }

    function _getInitialIbtPrice(address asset) internal view returns (uint256) {
        if (asset == _usdc) {
            return _usdcInitialIbtPrice;
        } else if (asset == _usdt) {
            return _usdtInitialIbtPrice;
        } else if (asset == _dai) {
            return _daiInitialIbtPrice;
        }
        return 1e18;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
