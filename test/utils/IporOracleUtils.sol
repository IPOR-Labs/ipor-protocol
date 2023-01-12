// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/MockIporWeighted.sol";

contract IporOracleUtils is Test {
    /// ------------------- ORACLE PARAMS -------------------
    struct OracleParams {
        uint32[] updateTimestamps;
        uint64[] exponentialMovingAverages;
        uint64[] exponentialWeightedMovingVariances;
    }
    /// ------------------- ORACLE PARAMS -------------------

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

    function getIporOracleOneAsset(address updater, address asset, uint64 ema) public returns (ItfIporOracle) {
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

    function getIporOracleThreeAssets(
        address updater,
        address[] memory tokenAddresses,
        uint32 updateTimestamp,
        uint64 exponentialMovingAverage,
        uint64 exponentialWeightedMovingVariance
    ) public returns (ItfIporOracle) {
        OracleParams memory oracleParams = _getSameIporOracleParamsForEachAsset(
            updateTimestamp, exponentialMovingAverage, exponentialWeightedMovingVariance
        );
        ItfIporOracle iporOracle = _prepareIporOracle(
            updater,
            tokenAddresses,
            oracleParams.updateTimestamps,
            oracleParams.exponentialMovingAverages,
            oracleParams.exponentialWeightedMovingVariances
        );
        return iporOracle;
    }

    /// ---------------- ORACLE PARAMS ----------------
    function _getSameIporOracleParamsForEachAsset(
        uint32 updateTimestamp,
        uint64 exponentialMovingAverage,
        uint64 exponentialWeightedMovingVariance
    ) internal pure returns (OracleParams memory) {
        OracleParams memory oracleParams;
        uint32[] memory updateTimestamps = new uint32[](3);
        uint64[] memory exponentialMovingAverages = new uint64[](3);
        uint64[] memory exponentialWeightedMovingVariances = new uint64[](3);
        updateTimestamps[0] = updateTimestamp;
        updateTimestamps[1] = updateTimestamp;
        updateTimestamps[2] = updateTimestamp;
        exponentialMovingAverages[0] = exponentialMovingAverage;
        exponentialMovingAverages[1] = exponentialMovingAverage;
        exponentialMovingAverages[2] = exponentialMovingAverage;
        exponentialWeightedMovingVariances[0] = exponentialWeightedMovingVariance;
        exponentialWeightedMovingVariances[1] = exponentialWeightedMovingVariance;
        exponentialWeightedMovingVariances[2] = exponentialWeightedMovingVariance;
        oracleParams.updateTimestamps = updateTimestamps;
        oracleParams.exponentialMovingAverages = exponentialMovingAverages;
        oracleParams.exponentialWeightedMovingVariances = exponentialWeightedMovingVariances;
        return oracleParams;
    }
    /// ---------------- ORACLE PARAMS ----------------
}
