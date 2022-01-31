// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporAssetConfiguration {
    //TODO: same order in interface and in implementation or remove if used immutable parameters
    event MiltonAddressUpdated(address indexed newAddress);
    event MiltonStorageAddressUpdated(address indexed newAddress);
    event JosephAddressUpdated(address indexed newJosephAddress);

    event IncomeTaxPercentageSet(uint256 newIncomeTaxPercentage);
    event LiquidationDepositAmountSet(uint256 newLiquidationDepositAmount);
    event OpeningFeePercentageSet(uint256 newOpeningFeePercentage);

    event OpeningFeeForTreasuryPercentageSet(
        uint256 newOpeningFeeForTreasuryPercentage
    );

    event IporPublicationFeeAmountSet(uint256 newIporPublicationFeeAmount);

    event LiquidityPoolMaxUtilizationPercentageSet(
        uint256 newLpMaxUtilizationPercentageSet
    );

    event LiquidityPoolMaxUtilizationPerLegPercentageSet(
        uint256 newLpMaxUtilizationPercentageSet
    );

    event RedeemMaxUtilizationPercentageSet(
        uint256 newRedeemMaxUtilizationPercentageSet
    );
    event MaxPositionTotalAmountSet(uint256 newMaxPositionTotalAmount);

    event MaxCollateralizationFactorValueSet(
        uint256 newMaxCollateralizationFactorValue
    );
    event MinCollateralizationFactorValueSet(
        uint256 newMinCollateralizationFactorValue
    );

    event AssetManagementVaultUpdated(
        address indexed asset,
        address indexed newAssetManagementVaultAddress
    );

    event CharlieTreasurerUpdated(
        address asset,
        address indexed newCharlieTreasurer
    );
    event TreasureTreasurerUpdated(
        address asset,
        address indexed newTreasureTreasurer
    );

    event DecayFactorValueUpdated(address asset, uint256 newDecayFactorValue);

    function getMilton() external view returns (address);

    function setMilton(address milton) external;

    function getMiltonStorage() external view returns (address);

    function setMiltonStorage(address miltonStorage) external;

    function getJoseph() external view returns (address);

    function setJoseph(address joseph) external;

    function getIncomeTaxPercentage() external view returns (uint256);

    function setIncomeTaxPercentage(uint256 incomeTaxPercentage) external;

    function getLiquidationDepositAmount() external view returns (uint256);

    function setLiquidationDepositAmount(uint256 liquidationDepositAmount)
        external;

    function getOpeningFeePercentage() external view returns (uint256);

    function setOpeningFeePercentage(uint256 openingFeePercentage) external;

    function getOpeningFeeForTreasuryPercentage()
        external
        view
        returns (uint256);

    function setOpeningFeeForTreasuryPercentage(
        uint256 openingFeeForTreasuryPercentage
    ) external;

    function getIporPublicationFeeAmount() external view returns (uint256);

    function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount)
        external;

    function getLiquidityPoolMaxUtilizationPercentage()
        external
        view
        returns (uint256);

    function setLiquidityPoolMaxUtilizationPercentage(
        uint256 newLpMaxUtilizationPercentage
    ) external;

    function getLiquidityPoolMaxUtilizationPerLegPercentage()
        external
        view
        returns (uint256);

    function setLiquidityPoolMaxUtilizationPerLegPercentage(
        uint256 newLpMaxUtilizationPercentage
    ) external;

    function getRedeemLpMaxUtilizationPercentage()
        external
        view
        returns (uint256);

    function setRedeemLpMaxUtilizationPercentage(
        uint256 newRedeemMaxUtilizationPercentage
    ) external;

    function getMaxSwapTotalAmount() external view returns (uint256);

    function setMaxSwapTotalAmount(uint256 maxSwapTotalAmount) external;

    function getMaxCollateralizationFactorValue()
        external
        view
        returns (uint256);

    function setMaxCollateralizationFactorValue(
        uint256 maxCollateralizationFactorValue
    ) external;

    function getMinCollateralizationFactorValue()
        external
        view
        returns (uint256);

    function setMinCollateralizationFactorValue(
        uint256 minCollateralizationFactorValue
    ) external;

    function getDecimals() external view returns (uint8);

    function getMaxSlippagePercentage() external view returns (uint256);

    function getIpToken() external view returns (address);

    function getCharlieTreasurer() external view returns (address);

    function setCharlieTreasurer(address charlieTreasurer) external;

    function getTreasureTreasurer() external view returns (address);

    function setTreasureTreasurer(address treasureTreasurer) external;

    function getAssetManagementVault() external view returns (address);

    function setAssetManagementVault(address newAssetManagementVaultAddress)
        external;

    function getDecayFactorValue() external view returns (uint256);

    function setDecayFactorValue(uint256 newDecayFactorValue) external;
}
