// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporVault.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../security/IporOwnableUpgradeable.sol";

contract MiltonConfiguration is IporOwnableUpgradeable, IMiltonConfiguration {
    //@notice max total amount used when opening position
    uint256 internal constant _MAX_SWAP_COLLATERAL_AMOUNT = 1e23;

    uint256 internal constant _MAX_SLIPPAGE_PERCENTAGE = 1e18;

    uint256 internal constant _MAX_LP_UTILIZATION_PERCENTAGE = 8 * 1e17;

    uint256 internal constant _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE =
        48 * 1e16;

    uint256 internal constant _INCOME_TAX_PERCENTAGE = 1e17;

    uint256 internal constant _OPENING_FEE_PERCENTAGE = 1e16;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big pie going to Treasury Balance
    uint256 internal constant _OPENING_FEE_FOR_TREASURY_PERCENTAGE = 0;

    uint256 internal constant _IPOR_PUBLICATION_FEE_AMOUNT = 10 * 1e18;

    uint256 internal constant _LIQUIDATION_DEPOSIT_AMOUNT = 20 * 1e18;

    uint256 internal constant _MAX_COLLATERALIZATION_FACTOR_VALUE = 1000 * 1e18;

    uint256 internal constant _MIN_COLLATERALIZATION_FACTOR_VALUE = 10 * 1e18;

    uint8 internal _decimals;
    address internal _asset;
    IIpToken internal _ipToken;
    IWarren internal _warren;
    IMiltonStorage internal _miltonStorage;
    IMiltonSpreadModel internal _miltonSpreadModel;
    IIporConfiguration internal _iporConfiguration;
    IIporAssetConfiguration internal _iporAssetConfiguration;
    IIporVault internal _iporVault;

    address internal _joseph;

    function getMiltonSpreadModel() external view override returns (address) {
        return address(_miltonSpreadModel);
    }

    function getMaxSwapCollateralAmount()
        external
        pure
        override
        returns (uint256)
    {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function getMaxSlippagePercentage()
        external
        pure
        override
        returns (uint256)
    {
        return _MAX_SLIPPAGE_PERCENTAGE;
    }

    function getMaxLpUtilizationPercentage()
        external
        pure
        override
        returns (uint256)
    {
        return _MAX_LP_UTILIZATION_PERCENTAGE;
    }

    function getMaxLpUtilizationPerLegPercentage()
        external
        pure
        override
        returns (uint256)
    {
        return _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE;
    }

    function getIncomeTaxPercentage() external pure override returns (uint256) {
        return _INCOME_TAX_PERCENTAGE;
    }

    function getOpeningFeePercentage()
        external
        pure
        override
        returns (uint256)
    {
        return _OPENING_FEE_PERCENTAGE;
    }

    function getOpeningFeeForTreasuryPercentage()
        external
        pure
        override
        returns (uint256)
    {
        return _OPENING_FEE_FOR_TREASURY_PERCENTAGE;
    }

    function getIporPublicationFeeAmount()
        external
        pure
        override
        returns (uint256)
    {
        return _IPOR_PUBLICATION_FEE_AMOUNT;
    }

    function getLiquidationDepositAmount()
        external
        pure
        override
        returns (uint256)
    {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function getMaxCollateralizationFactorValue()
        external
        pure
        override
        returns (uint256)
    {
        return _MAX_COLLATERALIZATION_FACTOR_VALUE;
    }

    function getMinCollateralizationFactorValue()
        external
        pure
        override
        returns (uint256)
    {
        return _MIN_COLLATERALIZATION_FACTOR_VALUE;
    }

    function setJoseph(address joseph) external override onlyOwner {
        _joseph = joseph;
        emit JosephUpdated(joseph);
    }

    function _getMaxSwapCollateralAmount()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MAX_SWAP_COLLATERAL_AMOUNT;
    }

    function _getMaxSlippagePercentage()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MAX_SLIPPAGE_PERCENTAGE;
    }

    function _getMaxLpUtilizationPercentage()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MAX_LP_UTILIZATION_PERCENTAGE;
    }

    function _getMaxLpUtilizationPerLegPercentage()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MAX_LP_UTILIZATION_PER_LEG_PERCENTAGE;
    }

    function _getIncomeTaxPercentage() internal pure virtual returns (uint256) {
        return _INCOME_TAX_PERCENTAGE;
    }

    function _getOpeningFeePercentage()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _OPENING_FEE_PERCENTAGE;
    }

    function _getOpeningFeeForTreasuryPercentage()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _OPENING_FEE_FOR_TREASURY_PERCENTAGE;
    }

    function _getIporPublicationFeeAmount()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _IPOR_PUBLICATION_FEE_AMOUNT;
    }

    function _getLiquidationDepositAmount()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _LIQUIDATION_DEPOSIT_AMOUNT;
    }

    function _getMaxCollateralizationFactorValue()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MAX_COLLATERALIZATION_FACTOR_VALUE;
    }

    function _getMinCollateralizationFactorValue()
        internal
        pure
        virtual
        returns (uint256)
    {
        return _MIN_COLLATERALIZATION_FACTOR_VALUE;
    }
}
