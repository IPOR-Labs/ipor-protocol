// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/interfaces/IIporRiskManagementOracle.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";

contract IporRiskManagementOracleUtils is Test {
    function getRiskManagementOracleAsset(
        address updater,
        address asset,
        uint16 maxUtilizationRatePerLeg,
        uint16 maxUtilizationRate,
        uint64 maxNotional,
        int24 baseSpread
    ) public returns (IIporRiskManagementOracle) {
        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicatorsList = new IporRiskManagementOracleTypes.RiskIndicators[](1);
        riskIndicatorsList[0] = IporRiskManagementOracleTypes.RiskIndicators({
            maxNotionalPayFixed: maxNotional,
            maxNotionalReceiveFixed: maxNotional,
            maxUtilizationRatePayFixed: maxUtilizationRatePerLeg,
            maxUtilizationRateReceiveFixed: maxUtilizationRatePerLeg,
            maxUtilizationRate: maxUtilizationRate
        });
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsList = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](1);
        baseSpreadsList[0] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
            spread28dPayFixed: baseSpread,
            spread28dReceiveFixed: baseSpread,
            spread60dPayFixed: baseSpread,
            spread60dReceiveFixed: baseSpread,
            spread90dPayFixed: baseSpread,
            spread90dReceiveFixed: baseSpread
        });
        address[] memory assets = new address[](1);
        assets[0] = asset;
        return _prepareRiskManagementOracle(updater, assets, riskIndicatorsList, baseSpreadsList);
    }

    function getRiskManagementOracleAssets(
        address updater,
        address[] memory assets,
        uint16 maxUtilizationRatePerLeg,
        uint16 maxUtilizationRate,
        uint64 maxNotional,
        int24 baseSpread
    ) public returns (IIporRiskManagementOracle) {
        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicatorsList = new IporRiskManagementOracleTypes.RiskIndicators[](assets.length);
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsList = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            riskIndicatorsList[i] = IporRiskManagementOracleTypes.RiskIndicators({
                maxNotionalPayFixed: maxNotional,
                maxNotionalReceiveFixed: maxNotional,
                maxUtilizationRatePayFixed: maxUtilizationRatePerLeg,
                maxUtilizationRateReceiveFixed: maxUtilizationRatePerLeg,
                maxUtilizationRate: maxUtilizationRate
            });
            baseSpreadsList[i] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
                spread28dPayFixed: baseSpread,
                spread28dReceiveFixed: baseSpread,
                spread60dPayFixed: baseSpread,
                spread60dReceiveFixed: baseSpread,
                spread90dPayFixed: baseSpread,
                spread90dReceiveFixed: baseSpread
            });
        }
        return _prepareRiskManagementOracle(updater, assets, riskIndicatorsList, baseSpreadsList);
    }

    function _prepareRiskManagementOracle(
        address updater,
        address[] memory assets,
        IporRiskManagementOracleTypes.RiskIndicators[] memory riskIndicatorsList,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[] memory baseSpreadsList
    ) internal returns (IporRiskManagementOracle) {
        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();
        ERC1967Proxy iporRiskManagementOracleProxy = new ERC1967Proxy(
            address(iporRiskManagementOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256)[])",
                assets,
                riskIndicatorsList,
                baseSpreadsList
            )
        );
        IporRiskManagementOracle iporRiskManagementOracle = IporRiskManagementOracle(
            address(iporRiskManagementOracleProxy)
        );
        iporRiskManagementOracle.addUpdater(updater);
        return iporRiskManagementOracle;
    }
}
