// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IIporAssetConfiguration {

    //TODO: same order in interface and in implementation

    event IncomeTaxPercentageSet(uint256 newIncomeTaxPercentage);
    event LiquidationDepositAmountSet(uint256 newLiquidationDepositAmount);
    event OpeningFeePercentageSet(uint256 newOpeningFeePercentage);

    event OpeningFeeForTreasuryPercentageSet(uint256 newOpeningFeeForTreasuryPercentage);

    event IporPublicationFeeAmountSet(uint256 newIporPublicationFeeAmount);

    event LiquidityPoolMaxUtilizationPercentageSet(uint256 newLiquidityPoolMaxUtilizationPercentageSet);
    event MaxPositionTotalAmountSet(uint256 newMaxPositionTotalAmount);

    event MaxCollateralizationFactorValueSet(uint256 newMaxCollateralizationFactorValue);
    event MinCollateralizationFactorValueSet(uint256 newMinCollateralizationFactorValue);

    event AssetManagementVaultUpdated(address indexed asset, address indexed newAssetManagementVaultAddress);
    event IpTokenAddressUpdated(address indexed asset, address indexed newIpTokenAddress);

    event CharlieTreasurerUpdated(address asset, address indexed newCharlieTreasurer);
    event TreasureTreasurerUpdated(address asset, address indexed newTreasureTreasurer);

    function getIncomeTaxPercentage() external view returns (uint256);

    function setIncomeTaxPercentage(uint256 incomeTaxPercentage) external;

    function getLiquidationDepositAmount() external view returns (uint256);

    function setLiquidationDepositAmount(uint256 liquidationDepositAmount) external;

    function getOpeningFeePercentage() external view returns (uint256);

    function setOpeningFeePercentage(uint256 openingFeePercentage) external;

    function getOpeningFeeForTreasuryPercentage() external view returns (uint256);

    function setOpeningFeeForTreasuryPercentage(uint256 openingFeeForTreasuryPercentage) external;

    function getIporPublicationFeeAmount() external view returns (uint256);

    function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount) external;

    function getLiquidityPoolMaxUtilizationPercentage() external view returns (uint256);

    function setLiquidityPoolMaxUtilizationPercentage(uint256 liquidityPoolMaxUtilizationPercentage) external;

    function getMaxPositionTotalAmount() external view returns (uint256);

    function setMaxPositionTotalAmount(uint256 maxPositionTotalAmount) external;

    function getSpreadPayFixedValue() external view returns (uint256);

    function setSpreadPayFixedValue(uint256 spread) external;

    function getSpreadRecFixedValue() external view returns (uint256);

    function setSpreadRecFixedValue(uint256 spread) external;

    function getMaxCollateralizationFactorValue() external view returns (uint256);

    function setMaxCollateralizationFactorValue(uint256 maxCollateralizationFactorValue) external;

    function getMinCollateralizationFactorValue() external view returns (uint256);

    function setMinCollateralizationFactorValue(uint256 minCollateralizationFactorValue) external;

    function getMultiplicator() external view returns(uint256);

    function getMaxSlippagePercentage() external view returns (uint256);

    function getIpToken() external view returns (address);

    function setIpToken(address ipToken) external;

    function getCharlieTreasurer() external view returns (address);

    function setCharlieTreasurer(address charlieTreasurer) external;

    function getTreasureTreasurer() external view returns (address);

    function setTreasureTreasurer(address treasureTreasurer) external;

    function getAssetManagementVault() external view returns (address);

    function setAssetManagementVault(address newAssetManagementVaultAddress) external;

}
