// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IProxyImplementation.sol";
import "../interfaces/IIporContractCommonGov.sol";
import "../interfaces/IAssetManagement.sol";
import "../interfaces/IStrategy.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AssetManagementErrors.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/IporContractValidator.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../security/PauseManager.sol";

abstract contract AssetManagement is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAssetManagement,
    IIporContractCommonGov,
    IProxyImplementation
{
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant ROUNDING_ERROR_MARGIN = 1e18;

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
    address internal _AmmTreasuryDeprecated;
    /// @dev deprecated
    address internal _strategyAaveDeprecated;
    /// @dev deprecated
    address internal _strategyCompoundDeprecated;

    address public immutable asset;
    address public immutable ammTreasury;
    uint256 public immutable supportedStrategiesVolume;
    uint256 public immutable highestApyStrategyArrayIndex;

    modifier onlyAmmTreasury() {
        require(msg.sender == ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    constructor(
        address assetInput,
        address ammTreasuryInput,
        uint256 supportedStrategiesVolumeInput,
        uint256 highestApyStrategyArrayIndexInput
    ) {
        asset = assetInput.checkAddress();
        ammTreasury = ammTreasuryInput.checkAddress();
        supportedStrategiesVolume = supportedStrategiesVolumeInput;
        highestApyStrategyArrayIndex = highestApyStrategyArrayIndexInput;

        require(_getDecimals() == IERC20MetadataUpgradeable(assetInput).decimals(), IporErrors.WRONG_DECIMALS);
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

        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, address(this), assetAmount);

        address wasDepositedToStrategy = address(0x0);

        uint256 amountNormalized = IporMath.convertToWad(
            IporMath.convertWadToAssetDecimals(amount, _getDecimals()),
            _getDecimals()
        );

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            try IStrategy(sortedStrategies[highestApyStrategyArrayIndex - i].strategy).deposit(amount) returns (
                uint256 tryDepositedAmount
            ) {
                require(
                    tryDepositedAmount > 0 && tryDepositedAmount <= amountNormalized,
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

        emit Deposit(msg.sender, wasDepositedToStrategy, depositedAmount);

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
        return _withdraw(type(uint256).max - ROUNDING_ERROR_MARGIN);
    }

    function getSortedStrategiesWithApy() external view returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = _getSortedStrategiesWithApy(_getStrategiesData());
    }

    function grantMaxAllowanceForSpender(address assetInput, address spender) external onlyOwner {
        IERC20Upgradeable(assetInput).forceApprove(spender, Constants.MAX_VALUE);
    }

    function revokeAllowanceForSpender(address assetInput, address spender) external onlyOwner {
        IERC20Upgradeable(assetInput).safeApprove(spender, 0);
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

    function _getDecimals() internal pure virtual returns (uint256);

    function _getStrategiesData() internal view virtual returns (StrategyData[] memory strategies);

    function _withdraw(uint256 amount) internal returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StrategyData[] memory sortedStrategies = _getSortedStrategiesWithApy(_getStrategiesData());

        uint256 strategyAmountToWithdraw;
        uint256 amountToWithdraw = amount;

        /// @dev Withdraw a little bit more to get at least requested amount even if appears rounding error
        /// in external DeFi protocol integrated with IPOR Asset Management
        amountToWithdraw = amount + ROUNDING_ERROR_MARGIN;

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            strategyAmountToWithdraw = sortedStrategies[i].balance <= amountToWithdraw
                ? sortedStrategies[i].balance
                : amountToWithdraw;

            if (strategyAmountToWithdraw == 0) {
                /// @dev if strategy has no balance, try to withdraw from next strategy
                continue;
            }

            try IStrategy(sortedStrategies[i].strategy).withdraw(strategyAmountToWithdraw) returns (
                uint256 tryWithdrawnAmount
            ) {
                amountToWithdraw = tryWithdrawnAmount > amountToWithdraw ? 0 : amountToWithdraw - tryWithdrawnAmount;

                sortedStrategies[i].balance = tryWithdrawnAmount > sortedStrategies[i].balance
                    ? 0
                    : sortedStrategies[i].balance - tryWithdrawnAmount;
            } catch {
                /// @dev If strategy withdraw fails, try to withdraw from next strategy
                continue;
            }
        }

        /// @dev Always all collected assets on AssetManagement are withdrawn to AmmTreasury
        uint256 withdrawnAssetAmount = IERC20Upgradeable(asset).balanceOf(address(this));

        if (withdrawnAssetAmount > 0) {
            /// @dev Always transfer all assets from AssetManagement to AmmTreasury
            IERC20Upgradeable(asset).safeTransfer(msg.sender, withdrawnAssetAmount);

            withdrawnAmount = IporMath.convertToWad(withdrawnAssetAmount, _getDecimals());

            emit Withdraw(msg.sender, withdrawnAmount);
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
