// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfMilton.sol";

contract MockMilton is ItfMilton {
    struct InitParam {
        uint256 maxSwapCollateralAmount;
        uint256 openingFeeRate;
        uint256 openingFeeTreasuryPortionRate;
        uint256 iporPublicationFee;
        uint256 liquidationDepositAmount;
        uint256 minLeverage;
    }
    uint256 public immutable maxSwapCollateralAmount;
    uint256 public immutable openingFeeRate;
    uint256 public immutable openingFeeTreasuryPortionRate;
    uint256 public immutable iporPublicationFee;
    uint256 public immutable liquidationDepositAmount;
    uint256 public immutable minLeverage;
    uint256 public immutable decimals;

    IMiltonStorage _mockMiltonStorage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address iporRiskManagementOracle,
        InitParam memory initParam,
        uint256 decimalsTemp
    ) ItfMilton(iporRiskManagementOracle) {
        maxSwapCollateralAmount = initParam.maxSwapCollateralAmount;
        openingFeeRate = initParam.openingFeeRate;
        openingFeeTreasuryPortionRate = initParam.openingFeeTreasuryPortionRate;
        iporPublicationFee = initParam.iporPublicationFee;
        liquidationDepositAmount = initParam.liquidationDepositAmount;
        minLeverage = initParam.minLeverage;
        decimals = decimalsTemp;
    }

    function setMockMiltonStorage(address mockMiltonStorage) external {
        _mockMiltonStorage = IMiltonStorage(mockMiltonStorage);
    }

    function _getMiltonStorage() internal view override returns (IMiltonStorage) {
        if (address(_mockMiltonStorage) != address(0)) {
            return _mockMiltonStorage;
        }
        return _miltonStorage;
    }
//
//    function _getMaxSwapCollateralAmount() internal view virtual override returns (uint256) {
//        return maxSwapCollateralAmount;
//    }
//
//    function _getOpeningFeeRate() internal view virtual override returns (uint256) {
//        return openingFeeRate;
//    }
//
//    function _getOpeningFeeTreasuryPortionRate() internal view virtual override returns (uint256) {
//        return openingFeeTreasuryPortionRate;
//    }
//
//    function _getIporPublicationFee() internal view virtual override returns (uint256) {
//        return iporPublicationFee;
//    }
//
//    function _getLiquidationDepositAmount() internal view virtual override returns (uint256) {
//        return liquidationDepositAmount;
//    }
//
//    function _getMinLeverage() internal view virtual override returns (uint256) {
//        return minLeverage;
//    }
//
    function _getDecimals() internal view virtual override returns (uint256) {
        return decimals;
    }
}
