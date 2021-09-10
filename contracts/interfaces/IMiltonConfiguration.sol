// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IMiltonConfiguration {

    event IncomeTaxPercentageSet(uint256 newIncomeTaxPercentage);
    event MaxIncomeTaxPercentageSet(uint256 newMaxIncomeTaxPercentage);

    event LiquidationDepositFeeAmountSet(uint256 newLiquidationDepositFeeAmount);
    event MaxLiquidationDepositFeeAmountSet(uint256 newMaxLiquidationDepositFeeAmount);

    event OpeningFeePercentageSet(uint256 newOpeningFeePercentage);
    event MaxOpeningFeePercentageSet(uint256 newMaxOpeningFeePercentage);
    event OpeningFeeForTreasuryPercentageSet(uint256 newOpeningFeeForTreasuryPercentage);

    event IporPublicationFeeAmountSet(uint256 newIporPublicationFeeAmount);
    event MaxIporPublicationFeeAmountSet(uint256 newMaxIporPublicationFeeAmount);

    event LiquidityPoolMaxUtilizationPercentageSet(uint256 newLiquidityPoolMaxUtilizationPercentageSet);
    event MaxPositionTotalAmountSet(uint256 newMaxPositionTotalAmount);

    event SpreadSet(uint256 newSpread);

    event MaxCollateralizationValueSet(uint256 newMaxCollateralizationValue);
    event MinCollateralizationValueSet(uint256 newMinCollateralizationValue);

    function getIncomeTaxPercentage() external view returns (uint256);

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external;

    function getMaxIncomeTaxPercentage() external view returns (uint256);

    function setMaxIncomeTaxPercentage(uint256 _maxIncomeTaxPercentage) external;

    function getLiquidationDepositFeeAmount() external view returns (uint256);

    function setLiquidationDepositFeeAmount(uint256 _liquidationDepositFeeAmount) external;

    function getMaxLiquidationDepositFeeAmount() external view returns (uint256);

    function setMaxLiquidationDepositFeeAmount(uint256 _maxLiquidationDepositFeeAmount) external;

    function getOpeningFeePercentage() external view returns (uint256);

    function setOpeningFeePercentage(uint256 _openingFeePercentage) external;

    function getMaxOpeningFeePercentage() external view returns (uint256);

    function setMaxOpeningFeePercentage(uint256 _maxOpeningFeePercentage) external;

    function getOpeningFeeForTreasuryPercentage() external view returns (uint256);

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external;

    function getIporPublicationFeeAmount() external view returns (uint256);

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount) external;

    function getMaxIporPublicationFeeAmount() external view returns (uint256);

    function setMaxIporPublicationFeeAmount(uint256 _maxIporPublicationFeeAmount) external;

    function getLiquidityPoolMaxUtilizationPercentage() external view returns (uint256);

    function setLiquidityPoolMaxUtilizationPercentage(uint256 _liquidityPoolMaxUtilizationPercentage) external;

    function getMaxPositionTotalAmount() external view returns (uint256);

    function setMaxPositionTotalAmount(uint256 _maxPositionTotalAmount) external;

    function getSpread() external view returns (uint256);

    function setSpread(uint256 _spread) external;

    function getMaxCollateralizationValue() external view returns (uint256);

    function setMaxCollateralizationValue(uint256 _maxCollateralizationValue) external;

    function getMinCollateralizationValue() external view returns (uint256);

    function setMinCollateralizationValue(uint256 _minCollateralizationValue) external;

}
