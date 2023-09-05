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
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IProxyImplementation.sol";

import "../interfaces/IStrategyDsr.sol";
import "../interfaces/IAssetManagementDsr.sol";
import "../libraries/errors/AssetManagementErrors.sol";
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
        /// @dev balance in 18 decimals
        uint256 balance;
        uint256 apy;
    }

    /// @dev deprecated
    address internal _assetDeprecated;
    /// @dev deprecated
    address internal _ivTokenDeprecated;
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

    modifier onlyAmmTreasury() {
        require(_msgSender() == ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    constructor(
        address assetInput,
        address ammTreasuryInput,
        uint256 supportedStrategiesVolumeInput,
        uint256 highestApyStrategyArrayIndexInput
    ) {
        require(_getDecimals() == IERC20MetadataUpgradeable(assetInput).decimals(), IporErrors.WRONG_DECIMALS);

        asset = assetInput.checkAddress();
        ammTreasury = ammTreasuryInput.checkAddress();
        supportedStrategiesVolume = supportedStrategiesVolumeInput;
        highestApyStrategyArrayIndex = highestApyStrategyArrayIndexInput;
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function totalBalance() external view override returns (uint256) {
        return _calculateTotalBalance(_getStrategiesData());
    }

    function deposit(
        uint256 amount
    ) external override whenNotPaused onlyAmmTreasury returns (uint256 vaultBalance, uint256 depositedAmount) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        uint256 assetAmount = IporMath.convertWadToAssetDecimals(amount, _getDecimals());
        require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StrategyData[] memory sortedStrategies = _getSortedStrategiesWithApy(_getStrategiesData());

        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), assetAmount);

        address wasDepositedToStrategy = address(0x0);

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            try IStrategyDsr(sortedStrategies[highestApyStrategyArrayIndex - i].strategy).deposit(amount) returns (
                uint256 tryDepositedAmount
            ) {
                require(
                    tryDepositedAmount > 0 && tryDepositedAmount <= amount,
                    AssetManagementErrors.STRATEGY_INCORRECT_DEPOSITED_AMOUNT
                );

                depositedAmount = tryDepositedAmount;
                wasDepositedToStrategy = sortedStrategies[highestApyStrategyArrayIndex - i].strategy;

                break;
            } catch {
                continue;
            }
        }

        require(wasDepositedToStrategy != address(0x0), AssetManagementErrors.DEPOSIT_TO_STRATEGY_FAILED);

        emit Deposit(block.timestamp, _msgSender(), wasDepositedToStrategy, depositedAmount);

        vaultBalance = _calculateTotalBalance(sortedStrategies) + depositedAmount;
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

    function getSortedStrategiesWithApy() external view returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = _getSortedStrategiesWithApy(_getStrategiesData());
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

    function _getStrategiesData() internal view virtual returns (StrategyData[] memory sortedStrategies);

    function _withdraw(uint256 amount) internal returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StrategyData[] memory sortedStrategies = _getSortedStrategiesWithApy(_getStrategiesData());

        uint256 amountToWithdraw = amount;

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            try
                IStrategyDsr(sortedStrategies[i].strategy).withdraw(
                    sortedStrategies[i].balance <= amountToWithdraw ? sortedStrategies[i].balance : amountToWithdraw
                )
            returns (uint256 tryWithdrawnAmount) {
                amountToWithdraw = tryWithdrawnAmount > amountToWithdraw ? 0 : amountToWithdraw - tryWithdrawnAmount;

                sortedStrategies[i].balance = tryWithdrawnAmount > sortedStrategies[i].balance
                    ? 0
                    : sortedStrategies[i].balance - tryWithdrawnAmount;
            } catch {
                /// @dev If strategy withdraw fails, try to withdraw from next strategy
                continue;
            }

            if (amountToWithdraw <= 1e18) {
                break;
            }
        }

        /// @dev Always all collected assets on Stanley are withdrawn to Milton
        uint256 withdrawnAssetAmount = IERC20Upgradeable(asset).balanceOf(address(this));

        if (withdrawnAssetAmount > 0) {
            /// @dev Always transfer all assets from Stanley to Milton
            IERC20Upgradeable(asset).safeTransfer(_msgSender(), withdrawnAssetAmount);

            withdrawnAmount = IporMath.convertToWad(withdrawnAssetAmount, _getDecimals());

            emit Withdraw(block.timestamp, _msgSender(), withdrawnAmount);
        }

        vaultBalance = _calculateTotalBalance(sortedStrategies);
    }

    function _calculateTotalBalance(
        StrategyData[] memory sortedStrategies
    ) internal view returns (uint256 totalBalance) {
        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            totalBalance += sortedStrategies[i].balance;
        }
        totalBalance += IporMath.convertToWad(IERC20Upgradeable(asset).balanceOf(address(this)), _getDecimals());
    }

    function _getSortedStrategiesWithApy(
        StrategyData[] memory strategies
    ) internal view returns (StrategyData[] memory) {
        uint256 length = strategies.length;
        for (uint256 i; i < length; ++i) {
            strategies[i].apy = IStrategyDsr(strategies[i].strategy).getApy();
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
