// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IMiltonConfiguration {
    function getMaxSwapTotalAmount() external pure returns (uint256);

    function getMaxSlippagePercentage() external pure returns (uint256);

    function getMaxLpUtilizationPercentage() external pure returns (uint256);

    function getMaxLpUtilizationPerLegPercentage()
        external
        pure
        returns (uint256);

    function getIncomeTaxPercentage() external pure returns (uint256);

    function getOpeningFeePercentage() external pure returns (uint256);

    function getOpeningFeeForTreasuryPercentage()
        external
        pure
        returns (uint256);

    function getIporPublicationFeeAmount() external pure returns (uint256);

    function getLiquidationDepositAmount() external pure returns (uint256);

    function getMaxCollateralizationFactorValue()
        external
        pure
        returns (uint256);

    function getMinCollateralizationFactorValue()
        external
        pure
        returns (uint256);
}
