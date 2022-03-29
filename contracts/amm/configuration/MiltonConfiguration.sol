// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/IIpToken.sol";
import "../../interfaces/IWarren.sol";
import "../../interfaces/IMiltonConfiguration.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "../../interfaces/IStanley.sol";
import "../../security/IporOwnableUpgradeable.sol";

abstract contract MiltonConfiguration is
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IMiltonConfiguration
{
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

    function getMiltonSpreadModel() external view override returns (address) {
        return address(_miltonSpreadModel);
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

    function getJoseph() external view override returns (address) {
        return _joseph;
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
}
