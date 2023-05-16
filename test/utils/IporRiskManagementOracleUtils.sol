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
        uint64 maxNotional
    ) public returns (IIporRiskManagementOracle) {
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint64[] memory maxNotionalPayFixed = new uint64[](1);
        maxNotionalPayFixed[0] = maxNotional;
        uint64[] memory maxNotionalReceiveFixed = new uint64[](1);
        maxNotionalReceiveFixed[0] = maxNotional;
        uint16[] memory maxUtilizationRatePayFixed = new uint16[](1);
        maxUtilizationRatePayFixed[0] = maxUtilizationRatePerLeg;
        uint16[] memory maxUtilizationRateReceiveFixed = new uint16[](1);
        maxUtilizationRateReceiveFixed[0] = maxUtilizationRatePerLeg;
        uint16[] memory maxUtilizationRates = new uint16[](1);
        maxUtilizationRates[0] = maxUtilizationRate;
        return
            _prepareRiskManagementOracle(
                updater,
                assets,
                maxNotionalPayFixed,
                maxNotionalReceiveFixed,
                maxUtilizationRatePayFixed,
                maxUtilizationRateReceiveFixed,
                maxUtilizationRates
            );
    }

    function getRiskManagementOracleAssets(
        address updater,
        address[] memory assets,
        uint16 maxUtilizationRatePerLeg,
        uint16 maxUtilizationRate,
        uint64 maxNotional
    ) public returns (IIporRiskManagementOracle) {
        uint64[] memory maxNotionalPayFixed = new uint64[](assets.length);
        uint64[] memory maxNotionalReceiveFixed = new uint64[](assets.length);
        uint16[] memory maxUtilizationRatePayFixed = new uint16[](assets.length);
        uint16[] memory maxUtilizationRateReceiveFixed = new uint16[](assets.length);
        uint16[] memory maxUtilizationRates = new uint16[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            maxNotionalPayFixed[i] = maxNotional;
            maxNotionalReceiveFixed[i] = maxNotional;
            maxUtilizationRatePayFixed[i] = maxUtilizationRatePerLeg;
            maxUtilizationRateReceiveFixed[i] = maxUtilizationRatePerLeg;
            maxUtilizationRates[i] = maxUtilizationRate;
        }
        return
            _prepareRiskManagementOracle(
                updater,
                assets,
                maxNotionalPayFixed,
                maxNotionalReceiveFixed,
                maxUtilizationRatePayFixed,
                maxUtilizationRateReceiveFixed,
                maxUtilizationRates
            );
    }

    function _prepareRiskManagementOracle(
        address updater,
        address[] memory assets,
        uint64[] memory maxNotionalPayFixed,
        uint64[] memory maxNotionalReceiveFixed,
        uint16[] memory maxUtilizationRatePayFixed,
        uint16[] memory maxUtilizationRateReceiveFixed,
        uint16[] memory maxUtilizationRate
    ) internal returns (IporRiskManagementOracle) {
        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();
        ERC1967Proxy iporRiskManagementOracleProxy = new ERC1967Proxy(
            address(iporRiskManagementOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint256[],uint256[],uint256[],uint256[],uint256[])",
                assets,
                maxNotionalPayFixed,
                maxNotionalReceiveFixed,
                maxUtilizationRatePayFixed,
                maxUtilizationRateReceiveFixed,
                maxUtilizationRate
            )
        );
        IporRiskManagementOracle iporRiskManagementOracle = IporRiskManagementOracle(address(iporRiskManagementOracleProxy));
        iporRiskManagementOracle.addUpdater(updater);
        return iporRiskManagementOracle;
    }
}
