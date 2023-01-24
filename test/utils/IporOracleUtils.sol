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
        require(tokenAddresses.length > 0 && tokenAddresses.length <= 3, "tokenAddresses length must be 1, 2 or 3");
        if(tokenAddresses.length == 1) {
            return getIporOracleAsset(updater, tokenAddresses[0], exponentialMovingAverage);
        }
        else if(tokenAddresses.length == 2) {
            OracleParams memory oracleParams = _getSameIporOracleParamsForTwoAssets(updateTimestamp, exponentialMovingAverage, exponentialWeightedMovingVariance);
            return _prepareIporOracle(
                updater,
                tokenAddresses,
                oracleParams.updateTimestamps,
                oracleParams.exponentialMovingAverages,
                oracleParams.exponentialWeightedMovingVariances
            );
        }
        else if(tokenAddresses.length == 3) {
            OracleParams memory oracleParams = _getSameIporOracleParamsForThreeAssets(updateTimestamp, exponentialMovingAverage, exponentialWeightedMovingVariance);
            return _prepareIporOracle(
                updater,
                tokenAddresses,
                oracleParams.updateTimestamps,
                oracleParams.exponentialMovingAverages,
                oracleParams.exponentialWeightedMovingVariances
            );
        }
        
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

    function _getSameIporOracleParamsForTwoAssets(
        uint32 updateTimestamp,
        uint64 exponentialMovingAverage,
        uint64 exponentialWeightedMovingVariance
    ) internal pure returns (OracleParams memory) {
        OracleParams memory oracleParams;
        uint32[] memory updateTimestamps = new uint32[](2);
        uint64[] memory exponentialMovingAverages = new uint64[](2);
        uint64[] memory exponentialWeightedMovingVariances = new uint64[](2);
        updateTimestamps[0] = updateTimestamp;
        updateTimestamps[1] = updateTimestamp;
        exponentialMovingAverages[0] = exponentialMovingAverage;
        exponentialMovingAverages[1] = exponentialMovingAverage;
        exponentialWeightedMovingVariances[0] = exponentialWeightedMovingVariance;
        exponentialWeightedMovingVariances[1] = exponentialWeightedMovingVariance;
        oracleParams.updateTimestamps = updateTimestamps;
        oracleParams.exponentialMovingAverages = exponentialMovingAverages;
        oracleParams.exponentialWeightedMovingVariances = exponentialWeightedMovingVariances;
        return oracleParams;
    }

    function _getSameIporOracleParamsForThreeAssets(
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
}