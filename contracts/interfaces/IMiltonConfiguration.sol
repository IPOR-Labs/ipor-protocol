// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IMiltonConfiguration {

    event IncomeTaxPercentageSet(uint256 newIncomeTaxPercentage);
    event LiquidationDepositAmountSet(uint256 newLiquidationDepositAmount);
    event OpeningFeePercentageSet(uint256 newOpeningFeePercentage);

    event OpeningFeeForTreasuryPercentageSet(uint256 newOpeningFeeForTreasuryPercentage);

    event IporPublicationFeeAmountSet(uint256 newIporPublicationFeeAmount);

    event LiquidityPoolMaxUtilizationPercentageSet(uint256 newLiquidityPoolMaxUtilizationPercentageSet);
    event MaxPositionTotalAmountSet(uint256 newMaxPositionTotalAmount);

    event MaxCollateralizationValueSet(uint256 newMaxCollateralizationValue);
    event MinCollateralizationValueSet(uint256 newMinCollateralizationValue);

    function getIncomeTaxPercentage() external view returns (uint256);

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external;

    function getLiquidationDepositAmount() external view returns (uint256);

    function setLiquidationDepositAmount(uint256 _liquidationDepositAmount) external;

    function getOpeningFeePercentage() external view returns (uint256);

    function setOpeningFeePercentage(uint256 _openingFeePercentage) external;

    function getOpeningFeeForTreasuryPercentage() external view returns (uint256);

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external;

    function getIporPublicationFeeAmount() external view returns (uint256);

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount) external;

    function getLiquidityPoolMaxUtilizationPercentage() external view returns (uint256);

    function setLiquidityPoolMaxUtilizationPercentage(uint256 _liquidityPoolMaxUtilizationPercentage) external;

    function getMaxPositionTotalAmount() external view returns (uint256);

    function setMaxPositionTotalAmount(uint256 _maxPositionTotalAmount) external;

    function getSpreadPayFixedValue(address asset) external view returns (uint256);

    function setSpreadPayFixedValue(address asset, uint256 _spread) external;

    function getSpreadRecFixedValue(address asset) external view returns (uint256);

    function setSpreadRecFixedValue(address asset, uint256 _spread) external;

    function getMaxCollateralizationValue() external view returns (uint256);

    function setMaxCollateralizationValue(uint256 _maxCollateralizationValue) external;

    function getMinCollateralizationValue() external view returns (uint256);

    function setMinCollateralizationValue(uint256 _minCollateralizationValue) external;

}
