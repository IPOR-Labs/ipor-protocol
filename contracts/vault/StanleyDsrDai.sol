// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/StanleyErrors.sol";
import "../interfaces/IIvToken.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyDsr.sol";
import "../interfaces/IStanleyDsr.sol";
import "../security/IporOwnableUpgradeable.sol";

interface IAsset {
    function getAsset() external view returns (address);
}

contract StanleyDsrDai is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStanleyDsr
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant _SUPPORTED_STRATEGIES_VOLUME = 3;
    uint256 private constant _HIGHEST_APY_STRATEGY_ARRAY_INDEX = 2;

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

    address internal immutable _asset;
    address internal immutable _milton;
    address internal immutable _strategyAave;
    address internal immutable _strategyCompound;
    address internal immutable _strategyDsr;
    address internal immutable _ivToken;

    struct StrategyData {
        address strategy;
        uint256 balance;
        uint256 apr;
    }

    struct StrategiesData {
        StrategyData aave;
        StrategyData compound;
        StrategyData dsr;
    }

    modifier onlyMilton() {
        require(_msgSender() == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        address milton,
        address strategyAave,
        address strategyCompound,
        address strategyDsr,
        address ivToken
    ) {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(milton != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyAave != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyCompound != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyDsr != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);

        require(
            _getDecimals() == IERC20MetadataUpgradeable(asset).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(milton).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(strategyAave).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() ==
                IERC20MetadataUpgradeable(IAsset(strategyCompound).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(strategyDsr).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(ivToken).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        IIvToken iivToken = IIvToken(ivToken);
        require(asset == iivToken.getAsset(), StanleyErrors.ASSET_MISMATCH);

        IStrategy strategyAaveObj = IStrategy(strategyAave);
        require(strategyAaveObj.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        IStrategy strategyCompoundObj = IStrategy(strategyCompound);
        require(strategyCompoundObj.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        IStrategyDsr strategyDsrObj = IStrategyDsr(strategyDsr);
        require(strategyDsrObj.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        _asset = asset;
        _milton = milton;
        _strategyAave = strategyAave;
        _strategyCompound = strategyCompound;
        _strategyDsr = strategyDsr;
        _ivToken = ivToken;

        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getVersion() external pure override returns (uint256) {
        return 3;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getIvToken() external view override returns (address) {
        return _ivToken;
    }

    function getMilton() external view override returns (address) {
        return _milton;
    }

    function getStrategyAave() external view override returns (address) {
        return _strategyAave;
    }

    function getStrategyCompound() external view override returns (address) {
        return _strategyCompound;
    }

    function getStrategyDsr() external view override returns (address) {
        return _strategyDsr;
    }

    function totalBalance(address who) external view override returns (uint256) {
        return _totalBalance();
    }

    function calculateExchangeRate() external view override returns (uint256 exchangeRate) {
        exchangeRate = _calcExchangeRate(_getStrategiesData());
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only Milton DAI can deposit
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(uint256 amount)
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 vaultBalance, uint256 depositedAmount)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StrategiesData memory strategiesData = _getStrategiesData();
        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(strategiesData);

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), amount);

        address wasDepositedToStrategy = address(0x0);

        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            try
                IStrategy(sortedStrategies[_HIGHEST_APY_STRATEGY_ARRAY_INDEX - i].strategy).deposit(
                    amount
                )
            returns (uint256 tryDepositedAmount) {
                require(
                    tryDepositedAmount > 0 && tryDepositedAmount <= amount,
                    StanleyErrors.STRATEGY_INCORRECT_DEPOSITED_AMOUNT
                );

                depositedAmount = tryDepositedAmount;
                wasDepositedToStrategy = sortedStrategies[_HIGHEST_APY_STRATEGY_ARRAY_INDEX - i]
                    .strategy;

                break;
            } catch {
                continue;
            }
        }

        require(wasDepositedToStrategy != address(0x0), StanleyErrors.DEPOSIT_TO_STRATEGY_FAILED);

        uint256 exchangeRate = _calcExchangeRate(strategiesData);

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);

        IIvToken(_ivToken).mint(_msgSender(), ivTokenAmount);

        emit Deposit(
            block.timestamp,
            _msgSender(),
            wasDepositedToStrategy,
            exchangeRate,
            depositedAmount,
            ivTokenAmount
        );

        vaultBalance = _calculateTotalBalance(strategiesData) + depositedAmount;
    }

    function withdraw(uint256 amount)
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(_getStrategiesData());

        uint256 amountToWithdraw = amount;

        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            try
                IStrategy(sortedStrategies[i].strategy).withdraw(
                    sortedStrategies[i].balance <= amountToWithdraw
                        ? sortedStrategies[i].balance
                        : amountToWithdraw
                )
            returns (uint256 tryWithdrawnAmount) {
                amountToWithdraw = tryWithdrawnAmount > amountToWithdraw
                    ? 0
                    : amountToWithdraw - tryWithdrawnAmount;

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
            uint256 exchangeRate = _calcExchangeRateSorted(sortedStrategies);

            uint256 ivTokenWithdrawnAmount = IporMath.division(
                withdrawnAmount * Constants.D18,
                exchangeRate
            );

            uint256 senderIvTokens = IIvToken(_ivToken).balanceOf(_msgSender());

            IIvToken(_ivToken).burn(
                _msgSender(),
                ivTokenWithdrawnAmount > senderIvTokens ? senderIvTokens : ivTokenWithdrawnAmount
            );

            /// @dev Always transfer all assets from Stanley to Milton
            asset.safeTransfer(_msgSender(), withdrawnAmount);

            emit Withdraw(
                block.timestamp,
                address(0x00),
                _msgSender(),
                exchangeRate,
                withdrawnAmount,
                ivTokenWithdrawnAmount
            );
        }

        vaultBalance = _calculateTotalBalanceSorted(sortedStrategies);
    }

    function withdrawAll()
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        address msgSender = _msgSender();
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        StrategiesData memory strategiesData = _getStrategiesData();

        if (strategiesData.aave.balance > 0) {
            IStrategy(_strategyAave).withdraw(strategiesData.aave.balance);
        }
        if (strategiesData.compound.balance > 0) {
            IStrategy(_strategyCompound).withdraw(strategiesData.compound.balance);
        }
        if (strategiesData.dsr.balance > 0) {
            IStrategy(_strategyDsr).withdraw(strategiesData.dsr.balance);
        }

        /// @dev Always all collected assets on Stanley are withdrawn to Milton
        withdrawnAmount = asset.balanceOf(address(this));

        uint256 ivBalance = IIvToken(_ivToken).balanceOf(msgSender);
        uint256 exchangeRate = _calcExchangeRate(strategiesData);
        IIvToken(_ivToken).burn(msgSender, ivBalance);

        /// @dev Always transfer all assets from Stanley to Milton
        asset.safeTransfer(msgSender, withdrawnAmount);

        emit Withdraw(
            block.timestamp,
            address(0x00),
            _msgSender(),
            exchangeRate,
            withdrawnAmount,
            ivBalance
        );
    }

    function grandMaxAllowanceForSpender(address asset, address spender) external onlyOwner {
        IERC20Upgradeable(asset).safeApprove(spender, Constants.MAX_VALUE);
    }

    function revokeAllowanceForSpender(address asset, address spender) external onlyOwner {
        IERC20Upgradeable(asset).safeApprove(spender, 0);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getMaxApyStrategy(StrategiesData memory strategiesData)
        internal
        view
        returns (StrategyData[] memory sortedStrategies)
    {
        StrategyData[] memory strategies = new StrategyData[](_SUPPORTED_STRATEGIES_VOLUME);
        strategiesData.aave.apr = IStrategy(strategiesData.aave.strategy).getApr();
        strategies[0] = strategiesData.aave;
        strategiesData.compound.apr = IStrategy(strategiesData.compound.strategy).getApr();
        strategies[1] = strategiesData.compound;
        strategiesData.dsr.apr = IStrategy(strategiesData.dsr.strategy).getApr();
        strategies[2] = strategiesData.dsr;

        sortedStrategies = _sortApr(strategies);
    }

    function _getDecimals() internal pure virtual returns (uint256) {
        return 18;
    }

    function _totalBalance() internal view returns (uint256) {
        return _calculateTotalBalance(_getStrategiesData());
    }

    function _getStrategiesData() internal view returns (StrategiesData memory strategiesData) {
        strategiesData.aave.strategy = _strategyAave;
        strategiesData.aave.balance = IStrategy(_strategyAave).balanceOf();
        strategiesData.compound.strategy = _strategyCompound;
        strategiesData.compound.balance = IStrategy(_strategyCompound).balanceOf();
        strategiesData.dsr.strategy = _strategyDsr;
        strategiesData.dsr.balance = IStrategy(_strategyDsr).balanceOf();
    }

    function _calculateTotalBalanceSorted(StrategyData[] memory sortedStrategies)
        internal
        view
        returns (uint256 returnedTotalBalance)
    {
        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            returnedTotalBalance += sortedStrategies[i].balance;
        }
        returnedTotalBalance += IERC20Upgradeable(_asset).balanceOf(address(this));
    }

    function _calculateTotalBalance(StrategiesData memory strategiesData)
        internal
        view
        returns (uint256)
    {
        return
            strategiesData.aave.balance +
            strategiesData.compound.balance +
            strategiesData.dsr.balance +
            IERC20Upgradeable(_asset).balanceOf(address(this));
    }

    function _calcExchangeRateSorted(StrategyData[] memory sortedStrategies)
        internal
        view
        returns (uint256)
    {
        uint256 totalAssetBalance = _calculateTotalBalanceSorted(sortedStrategies);
        uint256 ivTokenTotalSupply = IIvToken(_ivToken).totalSupply();

        return
            totalAssetBalance == 0 || ivTokenTotalSupply == 0
                ? Constants.D18
                : IporMath.division(totalAssetBalance * Constants.D18, ivTokenTotalSupply);
    }

    function _calcExchangeRate(StrategiesData memory strategiesData)
        internal
        view
        returns (uint256)
    {
        uint256 totalAssetBalance = _calculateTotalBalance(strategiesData);
        uint256 ivTokenTotalSupply = IIvToken(_ivToken).totalSupply();

        return
            totalAssetBalance == 0 || ivTokenTotalSupply == 0
                ? Constants.D18
                : IporMath.division(totalAssetBalance * Constants.D18, ivTokenTotalSupply);
    }

    function _sortApr(StrategyData[] memory data) internal pure returns (StrategyData[] memory) {
        _quickSortApr(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _quickSortApr(
        StrategyData[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        StrategyData memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].apr < pivot.apr) i++;
            while (pivot.apr < arr[uint256(j)].apr) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSortApr(arr, left, j);
        if (i < right) _quickSortApr(arr, i, right);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
