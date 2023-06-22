// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@ipor-protocol/contracts/itf/ItfIporOracle.sol";
import "@ipor-protocol/test/mocks/MockIporWeighted.sol";
import "@ipor-protocol/test/mocks/MockIporWeighted.sol";

contract IporOracleUtils is Test {
    struct OracleParams {
        uint32[] updateTimestamps;
    }

    function getIporOracleAsset(
        address updater,
        address asset
    ) public returns (ItfIporOracle) {
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(block.timestamp);
        ItfIporOracle iporOracle = _prepareIporOracle(
            updater,
            assets,
            updateTimestamps
        );
        return iporOracle;
    }

    function getIporOracleAssets(
        address updater,
        address[] memory tokenAddresses,
        uint32 updateTimestamp
    ) public returns (ItfIporOracle) {
        OracleParams memory oracleParams = _getSameIporOracleParamsForAssets(
            uint8(tokenAddresses.length),
            updateTimestamp
        );
        return
            _prepareIporOracle(
                updater,
                tokenAddresses,
                oracleParams.updateTimestamps
            );
    }

    function _prepareIporOracle(
        address updater,
        address[] memory tokenAddresses,
        uint32[] memory lastUpdateTimestamps
    ) internal returns (ItfIporOracle) {
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                tokenAddresses,
                lastUpdateTimestamps
            )
        );
        ItfIporOracle iporOracle = ItfIporOracle(address(iporOracleProxy));
        iporOracle.addUpdater(updater);
        return iporOracle;
    }

    function _prepareIporWeighted(address iporOracle) internal returns (MockIporWeighted) {
        MockIporWeighted iporWeightedImpl = new MockIporWeighted();
        ERC1967Proxy iporWeightedProxy = new ERC1967Proxy(
            address(iporWeightedImpl),
            abi.encodeWithSignature("initialize(address)", iporOracle)
        );
        return MockIporWeighted(address(iporWeightedProxy));
    }

    function _prepareIporOracle(
        address[] memory accounts,
        address[] memory tokenAddresses,
        uint32[] memory lastUpdateTimestamps
    ) internal returns (ItfIporOracle) {
        ItfIporOracle iporOracleImpl = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImpl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                tokenAddresses,
                lastUpdateTimestamps
            )
        );
        ItfIporOracle iporOracle = ItfIporOracle(address(iporOracleProxy));
        if (accounts[1] != address(0)) {
            iporOracle.addUpdater(accounts[1]);
        }
        return iporOracle;
    }

    function _getSameIporOracleParamsForAssets(
        uint8 numAssets,
        uint32 updateTimestamp
    ) internal pure returns (OracleParams memory) {
        OracleParams memory oracleParams;
        uint32[] memory updateTimestamps = new uint32[](numAssets);
        for (uint8 i = 0; i < numAssets; i++) {
            updateTimestamps[i] = updateTimestamp;
        }
        oracleParams.updateTimestamps = updateTimestamps;
        return oracleParams;
    }
}
