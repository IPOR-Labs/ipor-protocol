// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/MockIporWeighted.sol";
import "../../contracts/mocks/MockIporWeighted.sol";

contract IporOracleUtils is Test {

    struct OracleParams {
        uint32[] updateTimestamps;
        uint64[] exponentialMovingAverages;
        uint64[] exponentialWeightedMovingVariances;
    }

    function getIporOracleAsset(address updater, address asset, uint64 ema) public returns (ItfIporOracle) {
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(block.timestamp);
        uint64[] memory exponentialMovingAverages = new uint64[](1);
        exponentialMovingAverages[0] = ema;
        uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);
        exponentialWeightedMovingVariances[0] = 0;
        ItfIporOracle iporOracle = _prepareIporOracle(
            updater, assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances
        );
        return iporOracle;
    }

    function getIporOracleAssets(
        address updater,
        address[] memory tokenAddresses,
        uint32 updateTimestamp,
        uint64 exponentialMovingAverage,
        uint64 exponentialWeightedMovingVariance
    ) public returns (ItfIporOracle) {
        OracleParams memory oracleParams = _getSameIporOracleParamsForAssets(uint8(tokenAddresses.length), updateTimestamp, exponentialMovingAverage, exponentialWeightedMovingVariance);
        return _prepareIporOracle(
            updater,
            tokenAddresses,
            oracleParams.updateTimestamps,
            oracleParams.exponentialMovingAverages,
            oracleParams.exponentialWeightedMovingVariances
        );
    }

    function _prepareIporOracle(
        address updater,
        address[] memory tokenAddresses,
        uint32[] memory lastUpdateTimestamps,
        uint64[] memory exponentialMovingAverages,
        uint64[] memory exponentialWeightedMovingVariances
    ) internal returns (ItfIporOracle) {
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy =
        new ERC1967Proxy(address(iporOracleImplementation), abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", tokenAddresses, lastUpdateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
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
        uint32[] memory lastUpdateTimestamps,
        uint64[] memory exponentialMovingAverages,
        uint64[] memory exponentialWeightedMovingVariances
    ) internal returns (ItfIporOracle) {
        ItfIporOracle iporOracleImpl = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImpl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[],uint64[],uint64[])",
                tokenAddresses,
                lastUpdateTimestamps,
                exponentialMovingAverages,
                exponentialWeightedMovingVariances
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
        uint32 updateTimestamp,
        uint64 exponentialMovingAverage, 
        uint64 exponentialWeightedMovingVariance
    ) internal pure returns (OracleParams memory) {
        OracleParams memory oracleParams;
        uint32[] memory updateTimestamps = new uint32[](numAssets);
        uint64[] memory exponentialMovingAverages = new uint64[](numAssets);
        uint64[] memory exponentialWeightedMovingVariances = new uint64[](numAssets);
        for (uint8 i = 0; i < numAssets; i++) {
            updateTimestamps[i] = updateTimestamp;
            exponentialMovingAverages[i] = exponentialMovingAverage;
            exponentialWeightedMovingVariances[i] = exponentialWeightedMovingVariance;
        }
        oracleParams.updateTimestamps = updateTimestamps;
        oracleParams.exponentialMovingAverages = exponentialMovingAverages;
        oracleParams.exponentialWeightedMovingVariances = exponentialWeightedMovingVariances;
        return oracleParams;
    }

}