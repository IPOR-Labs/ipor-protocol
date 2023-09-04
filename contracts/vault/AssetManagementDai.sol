// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/errors/AssetManagementErrors.sol";

import "./AssetManagementCore.sol";

contract AssetManagementDai is AssetManagementCore {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant getVersion = 2_000;

    address public immutable strategyAave;
    address public immutable strategyCompound;
    address public immutable strategyDsr;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        address ammTreasuryInput,
        uint256 supportedStrategiesVolumeInput,
        uint256 highestApyStrategyArrayIndexInput,
        address strategyAaveInput,
        address strategyCompoundInput,
        address strategyDsrInput
    )
        AssetManagementCore(
            assetInput,
            ammTreasuryInput,
            supportedStrategiesVolumeInput,
            highestApyStrategyArrayIndexInput
        )
    {
        require(strategyAaveInput != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyCompoundInput != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyDsrInput != address(0), IporErrors.WRONG_ADDRESS);

        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyAaveInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyCompoundInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyDsrInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        IStrategy strategyAaveObj = IStrategy(strategyAaveInput);
        //        require(strategyAaveObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);
        //
        //        IStrategy strategyCompoundObj = IStrategy(strategyCompoundInput);
        //        require(strategyCompoundObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        //        IStrategyDsr strategyDsrObj = IStrategyDsr(strategyDsrInput);
        //        require(strategyDsrObj.asset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

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

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
            try IStrategy(sortedStrategies[highestApyStrategyArrayIndex - i].strategy).deposit(amount) returns (
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

    function _withdraw(uint256 amount) internal override returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IERC20Upgradeable asset = IERC20Upgradeable(asset);

        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(_getStrategiesData());

        uint256 amountToWithdraw = amount;

        for (uint256 i; i < supportedStrategiesVolume; ++i) {
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
        sortedStrategies = new StrategyData[](supportedStrategiesVolume);
        sortedStrategies[0].strategy = strategyAave;
        sortedStrategies[0].balance = IStrategy(strategyAave).balanceOf();
        sortedStrategies[1].strategy = strategyCompound;
        sortedStrategies[1].balance = IStrategy(strategyCompound).balanceOf();
        sortedStrategies[2].strategy = strategyDsr;
        sortedStrategies[2].balance = IStrategy(strategyDsr).balanceOf();
    }
}
