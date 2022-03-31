// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/Constants.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IStanley.sol";
import "./libraries/IporSwapLogic.sol";
import "../security/IporOwnableUpgradeable.sol";

abstract contract MiltonInternal is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
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

    uint256 internal constant _MAX_LP_UTILIZATION_PERCENTAGE = 8 * 1e17;

    uint256 internal constant _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE = 48 * 1e16;

    uint256 internal constant _INCOME_TAX_PERCENTAGE = 1e17;

    uint256 internal constant _OPENING_FEE_PERCENTAGE = 1e16;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance,
    //below value define how big pie going to Treasury Balance
    uint256 internal constant _OPENING_FEE_FOR_TREASURY_PERCENTAGE = 0;

    uint256 internal constant _IPOR_PUBLICATION_FEE_AMOUNT = 10 * 1e18;

    uint256 internal constant _LIQUIDATION_DEPOSIT_AMOUNT = 20 * 1e18;

    uint256 internal constant _MAX_LEVERAGE_VALUE = 1000 * 1e18;

    uint256 internal constant _MIN_LEVERAGE_VALUE = 10 * 1e18;

    uint256 internal constant _MIN_PERCENTAGE_POSITION_VALUE_WHEN_CLOSING_BEFORE_MATURITY =
        99 * 1e16;

    uint256 internal constant _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED = 6 hours;

    address internal _asset;
    IIpToken internal _ipToken;
    address internal _joseph;
    IWarren internal _warren;
    IMiltonStorage internal _miltonStorage;
    IMiltonSpreadModel internal _miltonSpreadModel;
    IStanley internal _stanley;

    modifier onlyJoseph() {
        require(msg.sender == _joseph, MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getMaxSwapCollateralAmount() external pure override returns (uint256) {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function getMaxLpUtilizationPercentage() external pure override returns (uint256) {
        return _MAX_LP_UTILIZATION_PERCENTAGE;
    }

    function getMaxLpUtilizationPerLegPercentage() external pure override returns (uint256) {
        return _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE;
    }

    function getIncomeFeePercentage() external pure override returns (uint256) {
        return _INCOME_TAX_PERCENTAGE;
    }

    function getOpeningFeePercentage() external pure override returns (uint256) {
        return _OPENING_FEE_PERCENTAGE;
    }

    function getOpeningFeeForTreasuryPercentage() external pure override returns (uint256) {
        return _OPENING_FEE_FOR_TREASURY_PERCENTAGE;
    }

    function getIporPublicationFeeAmount() external pure override returns (uint256) {
        return _IPOR_PUBLICATION_FEE_AMOUNT;
    }

    function getLiquidationDepositAmount() external pure override returns (uint256) {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function getMaxLeverageValue() external pure override returns (uint256) {
        return _MAX_LEVERAGE_VALUE;
    }

    function getMinLeverageValue() external pure override returns (uint256) {
        return _MIN_LEVERAGE_VALUE;
    }

    function getAccruedBalance()
        external
        view
        override
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        return _getAccruedBalance();
    }

    function calculateSoapForTimestamp(uint256 calculateTimestamp)
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

    function calculateSwapPayFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapPayFixedValue(block.timestamp, swap);
    }

    function calculateSwapReceiveFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapReceiveFixedValue(block.timestamp, swap);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external onlyJoseph nonReentrant whenNotPaused {
        uint256 vaultBalance = _stanley.deposit(assetAmount);
        _miltonStorage.updateStorageWhenDepositToStanley(assetAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount)
        external
        nonReentrant
        onlyJoseph
        whenNotPaused
    {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(assetAmount);
        _miltonStorage.updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromStanley() external nonReentrant onlyJoseph whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdrawAll();
        _miltonStorage.updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
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
        address oldJoseph = _joseph;
        _joseph = newJoseph;
        emit JosephChanged(msg.sender, oldJoseph, newJoseph);
    }

    function getJoseph() external view override returns (address) {
        return _joseph;
    }

    function getMiltonSpreadModel() external view override returns (address) {
        return address(_miltonSpreadModel);
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function _getMaxSwapCollateralAmount() internal pure virtual returns (uint256) {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function _getMaxLpUtilizationPercentage() internal pure virtual returns (uint256) {
        return _MAX_LP_UTILIZATION_PERCENTAGE;
    }

    function _getMaxLpUtilizationPerLegPercentage() internal pure virtual returns (uint256) {
        return _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE;
    }

    function _getIncomeFeePercentage() internal pure virtual returns (uint256) {
        return _INCOME_TAX_PERCENTAGE;
    }

    function _getOpeningFeePercentage() internal pure virtual returns (uint256) {
        return _OPENING_FEE_PERCENTAGE;
    }

    function _getOpeningFeeForTreasuryPercentage() internal pure virtual returns (uint256) {
        return _OPENING_FEE_FOR_TREASURY_PERCENTAGE;
    }

    function _getIporPublicationFeeAmount() internal pure virtual returns (uint256) {
        return _IPOR_PUBLICATION_FEE_AMOUNT;
    }

    function _getLiquidationDepositAmount() internal pure virtual returns (uint256) {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function _getMaxLeverageValue() internal pure virtual returns (uint256) {
        return _MAX_LEVERAGE_VALUE;
    }

    function _getMinLeverageValue() internal pure virtual returns (uint256) {
        return _MIN_LEVERAGE_VALUE;
    }

    function _getMinPercentagePositionValueWhenClosingBeforeMaturity()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MIN_PERCENTAGE_POSITION_VALUE_WHEN_CLOSING_BEFORE_MATURITY;
    }

    function _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _SECONDS_BEFORE_MATURITY_WHEN_POSITION_CAN_BE_CLOSED;
    }

    function _getAccruedBalance() internal view returns (IporTypes.MiltonBalancesMemory memory) {
        IporTypes.MiltonBalancesMemory memory accruedBalance = _miltonStorage.getBalance();

        uint256 actualVaultBalance = _stanley.totalBalance(address(this));
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
        uint256 accruedIbtPrice = _warren.calculateAccruedIbtPrice(_asset, calculateTimestamp);
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _miltonStorage
            .calculateSoap(accruedIbtPrice, calculateTimestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function _calculateSwapPayFixedValue(uint256 timestamp, IporTypes.IporSwapMemory memory swap)
        internal
        view
        returns (int256)
    {
        return
            swap.calculateSwapPayFixedValue(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _calculateSwapReceiveFixedValue(
        uint256 timestamp,
        IporTypes.IporSwapMemory memory swap
    ) internal view returns (int256) {
        return
            swap.calculateSwapReceiveFixedValue(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
    }
}
