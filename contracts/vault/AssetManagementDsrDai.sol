// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/AssetManagementErrors.sol";
import "../interfaces/IIvToken.sol";

import "../interfaces/IStrategyDsr.sol";
import "../interfaces/IAssetManagementDsr.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./AssetManagementCore.sol";
import "../security/PauseManager.sol";

contract AssetManagementDsrDai is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAssetManagementDsr,
    AssetManagementCore
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    uint256 public constant getVersion = 2_000;

    address public immutable strategyAave;
    address public immutable strategyCompound;
    address public immutable strategyDsr;

    modifier onlyAmmTreasury() {
        require(_msgSender() == ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        address ammTreasuryInput,
        address strategyAaveInput,
        address strategyCompoundInput,
        address strategyDsrInput
    ) AssetManagementCore(assetInput, ammTreasuryInput) {
        require(strategyAaveInput != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyCompoundInput != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyDsrInput != address(0), IporErrors.WRONG_ADDRESS);

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(strategyAaveInput).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(strategyCompoundInput).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(strategyDsrInput).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        IStrategy strategyAaveObj = IStrategy(strategyAaveInput);
        require(strategyAaveObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        IStrategy strategyCompoundObj = IStrategy(strategyCompoundInput);
        require(strategyCompoundObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        IStrategyDsr strategyDsrObj = IStrategyDsr(strategyDsrInput);
        require(strategyDsrObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        strategyAave = strategyAaveInput;
        strategyCompound = strategyCompoundInput;
        strategyDsr = strategyDsrInput;

        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function totalBalance() external view override returns (uint256) {
        return _calculateTotalBalance(_getStrategiesData());
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only Milton DAI can deposit
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(
        uint256 amount
    ) external override whenNotPaused onlyAmmTreasury returns (uint256 vaultBalance, uint256 depositedAmount) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(_getStrategiesData());

        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);

        address wasDepositedToStrategy = address(0x0);

        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            try IStrategy(sortedStrategies[_HIGHEST_APY_STRATEGY_ARRAY_INDEX - i].strategy).deposit(amount) returns (
                uint256 tryDepositedAmount
            ) {
                require(
                    tryDepositedAmount > 0 && tryDepositedAmount <= amount,
                    AssetManagementErrors.STRATEGY_INCORRECT_DEPOSITED_AMOUNT
                );

                depositedAmount = tryDepositedAmount;
                wasDepositedToStrategy = sortedStrategies[_HIGHEST_APY_STRATEGY_ARRAY_INDEX - i].strategy;

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

    function _withdraw(uint256 amount) internal returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IERC20Upgradeable asset = IERC20Upgradeable(asset);

        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(_getStrategiesData());

        uint256 amountToWithdraw = amount;

        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            try
                IStrategy(sortedStrategies[i].strategy).withdraw(
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
        withdrawnAmount = asset.balanceOf(address(this));

        if (withdrawnAmount > 0) {
            /// @dev Always transfer all assets from Stanley to Milton
            asset.safeTransfer(_msgSender(), withdrawnAmount);

            emit Withdraw(block.timestamp, _msgSender(), withdrawnAmount);
        }

        vaultBalance = _calculateTotalBalance(sortedStrategies);
    }

    function _getDecimals() internal pure override returns (uint256) {
        return 18;
    }

    function _getStrategiesData() internal view override returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = new StrategyData[](_SUPPORTED_STRATEGIES_VOLUME);
        sortedStrategies[0].strategy = strategyAave;
        sortedStrategies[0].balance = IStrategy(strategyAave).balanceOf();
        sortedStrategies[1].strategy = strategyCompound;
        sortedStrategies[1].balance = IStrategy(strategyCompound).balanceOf();
        sortedStrategies[2].strategy = strategyDsr;
        sortedStrategies[2].balance = IStrategy(strategyDsr).balanceOf();
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
