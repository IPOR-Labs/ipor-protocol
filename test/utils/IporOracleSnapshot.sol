// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/oracles/IporOracle.sol";
import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IporOracleSnapshot is Script {
    using stdJson for string;
    address private _iporOracle;
    address private _asset;
    address public iporOracleOwner;

    uint256 public iporOracleVersion;
    bool public iporOracleIsPaused;
    uint256 public blockNumber;
    uint256 public timestamp;

    // getIndex
    uint256 public indexValue;
    uint256 public ibtPrice;
    uint256 public exponentialMovingAverage;
    uint256 public exponentialWeightedMovingVariance;
    uint256 public lastUpdateTimestamp;
    //getAccruedIndex
    uint256 public accruedIndexValue;
    uint256 public accruedIbtPrice;
    uint256 public accruedExponentialMovingAverage;
    uint256 public accruedExponentialWeightedMovingVariance;


    constructor(address iporOracle, address asset) {
        _iporOracle = iporOracle;
        _asset = asset;
    }

    function snapshot() public {
        IporOracle iporOracle = IporOracle(_iporOracle);
        iporOracleOwner = iporOracle.owner();
        iporOracleVersion = iporOracle.getVersion();
        iporOracleIsPaused = iporOracle.paused();
        (
        indexValue,
        ibtPrice,
        exponentialMovingAverage,
        exponentialWeightedMovingVariance,
        lastUpdateTimestamp
        ) = iporOracle.getIndex(_asset);
        blockNumber = block.number;
        timestamp = block.timestamp;

        IporTypes.AccruedIpor memory accruedIpor = iporOracle.getAccruedIndex(block.timestamp, _asset);
        accruedIndexValue = accruedIpor.indexValue;
        accruedIbtPrice = accruedIpor.ibtPrice;
        accruedExponentialMovingAverage = accruedIpor.exponentialMovingAverage;
        accruedExponentialWeightedMovingVariance = accruedIpor.exponentialWeightedMovingVariance;

    }

    function toJson(string memory fileName) external returns(string memory pathToFile) {
        string memory path = vm.projectRoot();
        string memory iporOracleJson = "";

        vm.serializeAddress(iporOracleJson, "iporOracle", _iporOracle);
        vm.serializeAddress(
            iporOracleJson,
            "asset",
            _asset
        );

        vm.serializeAddress(
            iporOracleJson,
            "iporOracleOwner",
            iporOracleOwner
        );

        vm.serializeBool(
            iporOracleJson,
            "iporOracleIsPaused",
            iporOracleIsPaused
        );

        vm.serializeUint(
            iporOracleJson,
            "iporOracleVersion",
            iporOracleVersion
        );
        vm.serializeUint(
            iporOracleJson,
            "timestamp",
            timestamp
        );
        vm.serializeUint(
            iporOracleJson,
            "indexValue",
            indexValue
        );
        vm.serializeUint(
            iporOracleJson,
            "ibtPrice",
            ibtPrice
        );
        vm.serializeUint(
            iporOracleJson,
            "exponentialMovingAverage",
            exponentialMovingAverage
        );

        vm.serializeUint(
            iporOracleJson,
            "exponentialWeightedMovingVariance",
            exponentialWeightedMovingVariance
        );

        vm.serializeUint(
            iporOracleJson,
            "lastUpdateTimestamp",
            lastUpdateTimestamp
        );
        vm.serializeUint(
            iporOracleJson,
            "accruedIndexValue",
            accruedIndexValue
        );

        vm.serializeUint(
            iporOracleJson,
            "accruedIbtPrice",
            accruedIbtPrice
        );

        vm.serializeUint(
            iporOracleJson,
            "accruedExponentialMovingAverage",
            accruedExponentialMovingAverage
        );
        vm.serializeUint(
            iporOracleJson,
            "accruedExponentialWeightedMovingVariance",
            accruedExponentialWeightedMovingVariance
        );

        string memory finalJson = vm.serializeUint(
            iporOracleJson,
            "blockNumber",
            blockNumber
        );
        string memory fileBlockNumber = string.concat(
            Strings.toString(blockNumber),
            ".json"
        );
        string memory pathToFile = string.concat(path, fileName);
        vm.writeJson(finalJson, pathToFile);
        return pathToFile;
    }

    function fromJson(string memory fileName) public {
        string memory path = vm.projectRoot();
        string memory pathToFile = string.concat(path, fileName);
        string memory data = vm.readFile(pathToFile);

        _iporOracle = data.readAddress(
        "iporOracle"
        );
         _asset = data.readAddress(
             "asset"
         );
        iporOracleOwner = data.readAddress(
            "iporOracleOwner"
        );

        iporOracleVersion = data.readUint(
            "iporOracleVersion"
        );
        iporOracleIsPaused = data.readBool(
            "iporOracleIsPaused"
        );
        blockNumber = data.readUint(
            "blockNumber"
        );
        timestamp = data.readUint(
            "timestamp"
        );

        // getIndex
        indexValue = data.readUint(
            "indexValue"
        );
        ibtPrice = data.readUint(
            "ibtPrice"
        );
        exponentialMovingAverage = data.readUint(
            "exponentialMovingAverage"
        );
        exponentialWeightedMovingVariance = data.readUint(
            "exponentialWeightedMovingVariance"
        );
        lastUpdateTimestamp = data.readUint(
            "lastUpdateTimestamp"
        );
        //getAccruedIndex
        accruedIndexValue = data.readUint(
            "accruedIndexValue"
        );
        accruedIbtPrice = data.readUint(
            "accruedIbtPrice"
        );
        accruedExponentialMovingAverage = data.readUint(
            "accruedExponentialMovingAverage"
        );
        accruedExponentialWeightedMovingVariance = data.readUint(
            "accruedExponentialWeightedMovingVariance"
        );
    }

    function consoleLog() public {
        console2.log("iporOracleOwner", iporOracleOwner);
        console2.log("iporOracleVersion", iporOracleVersion);
        console2.log("iporOracleIsPaused", iporOracleIsPaused);
        console2.log("blockNumber", blockNumber);
        console2.log("timestamp", timestamp);
        console2.log("indexValue", indexValue);
        console2.log("ibtPrice", ibtPrice);
        console2.log("exponentialMovingAverage", exponentialMovingAverage);
        console2.log("exponentialWeightedMovingVariance", exponentialWeightedMovingVariance);
        console2.log("lastUpdateTimestamp", lastUpdateTimestamp);
        console2.log("accruedIndexValue", accruedIndexValue);
        console2.log("accruedIbtPrice", accruedIbtPrice);
        console2.log("accruedExponentialMovingAverage", accruedExponentialMovingAverage);
        console2.log("accruedExponentialWeightedMovingVariance", accruedExponentialWeightedMovingVariance);
    }
}
