// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../contracts/amm/pool/Joseph.sol";

contract JosephSnapshot is Script {
    address private _joseph;

    address public josephAsset;
    address public josephTreasury;
    address public josephCharlieTreasuryManager;
    address public josephCharlieTreasury;
    address public josephTreasuryManager;
    address public josephOwner;
    uint256 public josephVersion;
    uint256 public josephRedeemFeeRate;
    uint256 public josephRedeemLpMaxUtilizationRate;
    uint256 public josephMiltonStanleyBalanceRatio;
    uint256 public josephMaxLiquidityPoolBalance;
    uint256 public josephMaxLpAccountContribution;
    uint256 public josephExchangeRate;
    uint256 public josephVaultReservesRatio;
    bool public josephIsPaused;
    uint256 public blockNumber;
    uint256 public blockTimestamp;

    constructor(address joseph) {
        _joseph = joseph;
    }

    function snapshot() public {
        Joseph joseph = Joseph(_joseph);

        josephAsset = joseph.getAsset();
        josephTreasury = joseph.getTreasury();
        josephCharlieTreasuryManager = joseph
            .getCharlieTreasuryManager();
        josephCharlieTreasury = joseph.getCharlieTreasury();
        josephTreasuryManager = joseph.getTreasuryManager();
        josephOwner = joseph.owner();

        josephVersion = joseph.getVersion();
        josephRedeemFeeRate = joseph.getRedeemFeeRate();
        josephRedeemLpMaxUtilizationRate = joseph
            .getRedeemLpMaxUtilizationRate();
        josephMiltonStanleyBalanceRatio = joseph
            .getMiltonStanleyBalanceRatio();
        josephMaxLiquidityPoolBalance = joseph
            .getMaxLiquidityPoolBalance();
        josephMaxLpAccountContribution = joseph
            .getMaxLpAccountContribution();
        josephExchangeRate = joseph.calculateExchangeRate();

        josephIsPaused = joseph.paused();

        blockNumber = block.number;
        blockTimestamp = block.timestamp;
    }

    function toJson(string memory fileName) external {
        console2.log("START: Save Joseph data to json");

        string memory path = vm.projectRoot();
        string memory josephJson = "";

        vm.serializeAddress(josephJson, "josephAsset", josephAsset);
        vm.serializeAddress(josephJson, "josephTreasury", josephTreasury);
        vm.serializeAddress(
            josephJson,
            "josephCharlieTreasuryManager",
            josephCharlieTreasuryManager
        );
        vm.serializeAddress(
            josephJson,
            "josephCharlieTreasury",
            josephCharlieTreasury
        );
        vm.serializeAddress(
            josephJson,
            "josephTreasuryManager",
            josephTreasuryManager
        );
        vm.serializeAddress(josephJson, "josephOwner", josephOwner);

        vm.serializeUint(josephJson, "josephVersion", josephVersion);
        vm.serializeUint(
            josephJson,
            "josephRedeemFeeRate",
            josephRedeemFeeRate
        );
        vm.serializeUint(
            josephJson,
            "josephRedeemLpMaxUtilizationRate",
            josephRedeemLpMaxUtilizationRate
        );
        vm.serializeUint(
            josephJson,
            "josephMiltonStanleyBalanceRatio",
            josephMiltonStanleyBalanceRatio
        );
        vm.serializeUint(
            josephJson,
            "josephMaxLiquidityPoolBalance",
            josephMaxLiquidityPoolBalance
        );
        vm.serializeUint(
            josephJson,
            "josephMaxLpAccountContribution",
            josephMaxLpAccountContribution
        );
        vm.serializeUint(josephJson, "josephExchangeRate", josephExchangeRate);
        vm.serializeUint(
            josephJson,
            "josephVaultReservesRatio",
            josephVaultReservesRatio
        );

        vm.serializeBool(josephJson, "josephIsPaused", josephIsPaused);

        string memory finalJson = vm.serializeUint(
            josephJson,
            "blockNumber",
            blockNumber
        );
        string memory fileBlockNumber = string.concat(
            Strings.toString(blockNumber),
            ".json"
        );
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save Joseph data to json");
    }
}
