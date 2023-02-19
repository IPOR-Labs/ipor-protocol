// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/Constants.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IStanley.sol";
import "./libraries/IporSwapLogic.sol";
import "../security/IporOwnableUpgradeable.sol";

abstract contract MiltonInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMiltonInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    //@notice max total amount used when opening position
    uint256 internal constant _MAX_SWAP_COLLATERAL_AMOUNT = 1e23;

    uint256 internal constant _MAX_LP_UTILIZATION_RATE = 8 * 1e17;

    uint256 internal constant _MAX_LP_UTILIZATION_PER_LEG_RATE = 5 * 1e16;

    uint256 internal constant _INCOME_TAX_RATE = 1e17;

    uint256 internal constant _OPENING_FEE_RATE = 1e16;

    /// @notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance,
    /// below value define how big pie going to Treasury Balance
    uint256 internal constant _OPENING_FEE_FOR_TREASURY_PORTION_RATE = 0;

    uint256 internal constant _IPOR_PUBLICATION_FEE = 10 * 1e18;

    uint256 internal constant _LIQUIDATION_DEPOSIT_AMOUNT = 25;

    uint256 internal constant _MAX_LEVERAGE = 100 * 1e18;

    uint256 internal constant _MIN_LEVERAGE = 10 * 1e18;

    uint256 internal constant _MIN_LIQUIDATION_THRESHOLD_TO_CLOSE_BEFORE_MATURITY = 99 * 1e16;

    uint256 internal constant _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED = 6 hours;

    uint256 internal constant _LIQUIDATION_LEG_LIMIT = 10;

    address internal _asset;
    address internal _joseph;
    IStanley internal _stanley;
    IIporOracle internal _iporOracle;
    IMiltonStorage internal _miltonStorage;
    IMiltonSpreadModel internal _miltonSpreadModel;

    uint32 internal _autoUpdateIporIndexThreshold;

    mapping(address => bool) internal _swapLiquidators;

    modifier onlyJoseph() {
        require(_msgSender() == _getJoseph(), MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getIporOracle() external view returns (address) {
        return address(_iporOracle);
    }

    function getMiltonStorage() external view returns (address) {
        return address(_miltonStorage);
    }

    function getStanley() external view returns (address) {
        return address(_stanley);
    }

    function getMaxSwapCollateralAmount() external view override returns (uint256) {
        return _getMaxSwapCollateralAmount();
    }

    function getMaxLpUtilizationRate() external view override returns (uint256) {
        return _getMaxLpUtilizationRate();
    }

    function getMaxLpUtilizationPerLegRate() external view override returns (uint256) {
        return _getMaxLpUtilizationPerLegRate();
    }

    function getIncomeFeeRate() external view override returns (uint256) {
        return _getIncomeFeeRate();
    }

    function getOpeningFeeRate() external view override returns (uint256) {
        return _getOpeningFeeRate();
    }

    function getOpeningFeeTreasuryPortionRate() external view override returns (uint256) {
        return _getOpeningFeeTreasuryPortionRate();
    }

    function getIporPublicationFee() external view override returns (uint256) {
        return _getIporPublicationFee();
    }

    /// @notice Returns configured liquidation deposit amount
    /// @return liquidation deposit amount, value represented WITHOUT decimals
    function getLiquidationDepositAmount() external view override returns (uint256) {
        return _getLiquidationDepositAmount();
    }

    function getWadLiquidationDepositAmount() external view override returns (uint256) {
        return _getLiquidationDepositAmount() * Constants.D18;
    }

    function getMaxLeverage() external view override returns (uint256) {
        return _getMaxLeverage();
    }

    function getMinLeverage() external view override returns (uint256) {
        return _getMinLeverage();
    }

    function getAccruedBalance()
        external
        view
        override
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        return _getAccruedBalance();
    }

    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(
            calculateTimestamp
        );
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function calculatePayoffPayFixed(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculatePayoffPayFixed(block.timestamp, swap);
    }

    function calculatePayoffReceiveFixed(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculatePayoffReceiveFixed(block.timestamp, swap);
    }

    /// @notice Joseph deposits to Stanley asset amount from Milton.
    /// @param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external onlyJoseph nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = _getStanley().deposit(assetAmount);
        _getMiltonStorage().updateStorageWhenDepositToStanley(depositedAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount)
        external
        nonReentrant
        onlyJoseph
        whenNotPaused
    {
        _withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function _withdrawFromStanley(uint256 assetAmount) internal {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _getStanley().withdraw(assetAmount);
        _getMiltonStorage().updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromStanley() external nonReentrant onlyJoseph whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _getStanley().withdrawAll();
        _getMiltonStorage().updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setupMaxAllowanceForAsset(address spender) external override onlyOwner whenNotPaused {
        IERC20Upgradeable(_asset).safeIncreaseAllowance(spender, Constants.MAX_VALUE);
    }

    function setJoseph(address newJoseph) external override onlyOwner whenNotPaused {
        require(newJoseph != address(0), IporErrors.WRONG_ADDRESS);
        address oldJoseph = _getJoseph();
        _joseph = newJoseph;
        emit JosephChanged(_msgSender(), oldJoseph, newJoseph);
    }

    function getJoseph() external view override returns (address) {
        return _getJoseph();
    }

    function setMiltonSpreadModel(address newMiltonSpreadModel)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newMiltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        address oldMiltonSpreadModel = address(_miltonSpreadModel);
        _miltonSpreadModel = IMiltonSpreadModel(newMiltonSpreadModel);
        emit MiltonSpreadModelChanged(_msgSender(), oldMiltonSpreadModel, newMiltonSpreadModel);
    }

    function getMiltonSpreadModel() external view override returns (address) {
        return address(_miltonSpreadModel);
    }

    function setAutoUpdateIporIndexThreshold(uint256 newThreshold)
        external
        override
        onlyOwner
        whenNotPaused
    {
        uint256 oldThreshold = _autoUpdateIporIndexThreshold;
        _autoUpdateIporIndexThreshold = newThreshold.toUint32();
        emit AutoUpdateIporIndexThresholdChanged(_msgSender(), oldThreshold, newThreshold);
    }

    function getAutoUpdateIporIndexThreshold() external view override returns (uint256) {
        return _getAutoUpdateIporIndexThreshold();
    }

    function addSwapLiquidator(address newSwapLiquidator)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newSwapLiquidator != address(0), IporErrors.WRONG_ADDRESS);
        _swapLiquidators[newSwapLiquidator] = true;
        emit SwapLiquidatorAdded(newSwapLiquidator);
    }

    function removeSwapLiquidator(address liquidator) external override onlyOwner whenNotPaused {
        require(liquidator != address(0), IporErrors.WRONG_ADDRESS);
        _swapLiquidators[liquidator] = false;
        emit SwapLiquidatorRemoved(liquidator);
    }

    function isSwapLiquidator(address account) external view override returns (bool) {
        return _swapLiquidators[account];
    }

    function _getAutoUpdateIporIndexThreshold() internal view returns (uint256) {
        return _autoUpdateIporIndexThreshold * Constants.D21;
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function _getMaxSwapCollateralAmount() internal view virtual returns (uint256) {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function _getMaxLpUtilizationRate() internal view virtual returns (uint256) {
        return _MAX_LP_UTILIZATION_RATE;
    }

    function _getMaxLpUtilizationPerLegRate() internal view virtual returns (uint256) {
        return _MAX_LP_UTILIZATION_PER_LEG_RATE;
    }

    function _getIncomeFeeRate() internal view virtual returns (uint256) {
        return _INCOME_TAX_RATE;
    }

    function _getOpeningFeeRate() internal view virtual returns (uint256) {
        return _OPENING_FEE_RATE;
    }

    function _getOpeningFeeTreasuryPortionRate() internal view virtual returns (uint256) {
        return _OPENING_FEE_FOR_TREASURY_PORTION_RATE;
    }

    function _getIporPublicationFee() internal view virtual returns (uint256) {
        return _IPOR_PUBLICATION_FEE;
    }

    function _getLiquidationDepositAmount() internal view virtual returns (uint256) {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function _getMaxLeverage() internal view virtual returns (uint256);

    function _getMinLeverage() internal view virtual returns (uint256) {
        return _MIN_LEVERAGE;
    }

    function _getMinLiquidationThresholdToCloseBeforeMaturity()
        internal
        view
        virtual
        returns (uint256)
    {
        return _MIN_LIQUIDATION_THRESHOLD_TO_CLOSE_BEFORE_MATURITY;
    }

    function _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        internal
        view
        virtual
        returns (uint256)
    {
        return _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED;
    }

    function _getLiquidationLegLimit() internal view virtual returns (uint256) {
        return _LIQUIDATION_LEG_LIMIT;
    }

    function _getJoseph() internal view virtual returns (address) {
        return _joseph;
    }

    function _getIporOracle() internal view virtual returns (IIporOracle) {
        return _iporOracle;
    }

    function _getMiltonStorage() internal view virtual returns (IMiltonStorage) {
        return _miltonStorage;
    }

    function _getStanley() internal view virtual returns (IStanley) {
        return _stanley;
    }

    function _getAccruedBalance() internal view returns (IporTypes.MiltonBalancesMemory memory) {
        IporTypes.MiltonBalancesMemory memory accruedBalance = _getMiltonStorage().getBalance();

        uint256 actualVaultBalance = _getStanley().totalBalance(address(this));

        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, MiltonErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();

        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }

    function _calculateSoap(uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(
            _asset,
            calculateTimestamp
        );
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _getMiltonStorage()
            .calculateSoap(accruedIbtPrice, calculateTimestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function _calculatePayoffPayFixed(uint256 timestamp, IporTypes.IporSwapMemory memory swap)
        internal
        view
        returns (int256)
    {
        return
            swap.calculatePayoffPayFixed(
                timestamp,
                _getIporOracle().calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _calculatePayoffReceiveFixed(uint256 timestamp, IporTypes.IporSwapMemory memory swap)
        internal
        view
        returns (int256)
    {
        return
            swap.calculatePayoffReceiveFixed(
                timestamp,
                _getIporOracle().calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _getTimeBeforeMaturityAllowedToCloseSwapByBuyer()
        internal
        pure
        virtual
        returns (uint256)
    {
        return 1 days;
    }

    function _getTimeBeforeMaturityAllowedToCloseSwapByAnyone()
        internal
        pure
        virtual
        returns (uint256)
    {
        return 1 hours;
    }
}
