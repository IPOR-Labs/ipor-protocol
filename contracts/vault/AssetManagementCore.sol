// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "../interfaces/IStrategy.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IProxyImplementation.sol";
//TODO: remove
import "../interfaces/IIvToken.sol";
import "../interfaces/IStrategyDsr.sol";
import "../interfaces/IAssetManagementDsr.sol";

import "../security/PauseManager.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";

interface IAssetCheck {
    function getAsset() external view returns (address);
}

abstract contract AssetManagementCore is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAssetManagementDsr,
    IProxyImplementation
{
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StrategyData {
        address strategy;
        uint256 balance;
        uint256 apy;
    }

    /// @dev deprecated
    address internal _assetDeprecated;
    /// @dev deprecated
    IIvToken internal _ivTokenDeprecated;
    /// @dev deprecated
    address internal _miltonDeprecated;
    /// @dev deprecated
    address internal _strategyAaveDeprecated;
    /// @dev deprecated
    address internal _strategyCompoundDeprecated;

    address public immutable asset;
    address public immutable ammTreasury;
    uint256 public immutable supportedStrategiesVolume;
    uint256 public immutable highestApyStrategyArrayIndex;

    constructor(address assetInput, address ammTreasuryInput, uint256 supportedStrategiesVolumeInput, uint256 highestApyStrategyArrayIndexInput) {
        require(_getDecimals() == IERC20MetadataUpgradeable(assetInput).decimals(), IporErrors.WRONG_DECIMALS);

        asset = assetInput.checkAddress();
        ammTreasury = ammTreasuryInput.checkAddress();
        supportedStrategiesVolume = supportedStrategiesVolumeInput;
        highestApyStrategyArrayIndex = highestApyStrategyArrayIndexInput;
    }

    modifier onlyAmmTreasury() {
        require(_msgSender() == ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function totalBalance() external view override returns (uint256) {
        return _calculateTotalBalance(_getStrategiesData());
    }

    function withdraw(
        uint256 amount
    ) external override whenNotPaused onlyAmmTreasury returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        return _withdraw(amount);
    }

    function withdrawAll()
        external
        override
        whenNotPaused
        onlyAmmTreasury
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        return _withdraw(type(uint256).max);
    }

    function grantMaxAllowanceForSpender(address asset, address spender) external onlyOwner {
        IERC20Upgradeable(asset).safeApprove(spender, Constants.MAX_VALUE);
    }

    function revokeAllowanceForSpender(address asset, address spender) external onlyOwner {
        IERC20Upgradeable(asset).safeApprove(spender, 0);
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

    function addPauseGuardian(address guardian) external override onlyOwner {
        PauseManager.addPauseGuardian(guardian);
    }

    function removePauseGuardian(address guardian) external override onlyOwner {
        PauseManager.removePauseGuardian(guardian);
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function _withdraw(uint256 amount) internal virtual returns (uint256 withdrawnAmount, uint256 vaultBalance);

    function _getStrategiesData() internal view virtual returns (StrategyData[] memory sortedStrategies);

    function _calculateTotalBalance(
        StrategyData[] memory sortedStrategies
    ) internal view returns (uint256 totalBalance) {
        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            totalBalance += sortedStrategies[i].balance;
        }
        totalBalance += IERC20Upgradeable(asset).balanceOf(address(this));
    }

    //TODO: change name
    function getMaxApyStrategy() external view returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = _getMaxApyStrategy(_getStrategiesData());
    }

    function _getMaxApyStrategy(StrategyData[] memory strategies) internal view returns (StrategyData[] memory) {
        uint256 length = strategies.length;
        for (uint256 i; i < length; ++i) {
            strategies[i].apy = IStrategy(strategies[i].strategy).getApy();
        }
        return _sortApy(strategies);
    }

    function _sortApy(StrategyData[] memory data) internal pure returns (StrategyData[] memory) {
        _quickSortApy(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _quickSortApy(StrategyData[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        StrategyData memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].apy < pivot.apy) i++;
            while (pivot.apy < arr[uint256(j)].apy) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSortApy(arr, left, j);
        if (i < right) _quickSortApy(arr, i, right);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
