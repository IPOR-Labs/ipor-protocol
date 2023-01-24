// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../contracts/vault/Stanley.sol";
import "../../contracts/vault/strategies/StrategyCore.sol";
import "forge-std/Test.sol";

contract StanleySnapshot is Script, Test {
    address private _stanley;
    uint256 public stanleyVersion;
    uint256 public stanleyExchangeRate;
    address public stanleyAsset;
    address public stanleyMilton;
    address public strategyAave;
    address public strategyCompound;
    bool public stanleyIsPaused;
    uint256 public stanleyTotalBalance;
    address public stanleyOwner;
    uint256 public strategyAaveVersion;
    address public strategyAaveAsset;
    address public strategyAaveOwner;
    address public strategyAaveShareToken;
    uint256 public strategyAaveApr;
    uint256 public strategyAaveBalance;
    address public strategyAaveStanley;
    address public strategyAaveTreasury;
    address public strategyAaveTreasuryManager;
    bool public strategyAaveIsPaused;

    uint256 public strategyCompoundVersion;
    address public strategyCompoundAsset;
    address public strategyCompoundOwner;
    address public strategyCompoundShareToken;
    uint256 public strategyCompoundApr;
    uint256 public strategyCompoundBalance;
    address public strategyCompoundStanley;
    address public strategyCompoundTreasury;
    address public strategyCompoundTreasuryManager;
    bool public strategyCompoundIsPaused;

    uint256 public blockNumber;

    constructor(address stanley) {
        _stanley = stanley;
    }

    function snapshot() public {
        Stanley stanley = Stanley(_stanley);

        stanleyVersion = stanley.getVersion();
        stanleyAsset = stanley.getAsset();
        stanleyMilton = stanley.getMilton();
        strategyAave = stanley.getStrategyAave();
        strategyCompound = stanley.getStrategyCompound();
        stanleyIsPaused = stanley.paused();
        stanleyOwner = stanley.owner();
        stanleyTotalBalance = stanley.totalBalance(stanleyMilton);
        stanleyExchangeRate = stanley.calculateExchangeRate();
        StrategyCore aaveStrategy = StrategyCore(strategyAave);
        strategyAaveVersion = aaveStrategy.getVersion();
        strategyAaveAsset = aaveStrategy.getAsset();
        strategyAaveOwner = aaveStrategy.owner();
        strategyAaveShareToken = aaveStrategy.getShareToken();
        strategyAaveApr = aaveStrategy.getApr();
        strategyAaveBalance = aaveStrategy.balanceOf();
        strategyAaveStanley = aaveStrategy.getStanley();
        strategyAaveTreasury = aaveStrategy.getTreasury();
        strategyAaveTreasuryManager = aaveStrategy.getTreasuryManager();
        strategyAaveIsPaused = aaveStrategy.paused();

        StrategyCore compoundStrategy = StrategyCore(strategyCompound);
        strategyCompoundVersion = compoundStrategy.getVersion();
        strategyCompoundAsset = compoundStrategy.getAsset();
        strategyCompoundOwner = compoundStrategy.owner();
        strategyCompoundShareToken = compoundStrategy.getShareToken();
        strategyCompoundApr = compoundStrategy.getApr();
        strategyCompoundBalance = compoundStrategy.balanceOf();
        strategyCompoundStanley = compoundStrategy.getStanley();
        strategyCompoundTreasury = compoundStrategy.getTreasury();
        strategyCompoundTreasuryManager = compoundStrategy.getTreasuryManager();
        strategyCompoundIsPaused = compoundStrategy.paused();

        blockNumber = block.number;
    }

    function toJson(string memory fileName) external {
        console2.log("START: Save Stanley data to json");
        string memory path = vm.projectRoot();
        string memory stanleyJson = "";
        vm.serializeUint(stanleyJson, "stanleyVersion", stanleyVersion);
        vm.serializeUint(
            stanleyJson,
            "stanleyExchangeRate",
            stanleyExchangeRate
        );
        vm.serializeAddress(stanleyJson, "stanleyAsset", stanleyAsset);
        vm.serializeAddress(stanleyJson, "stanleyMilton", stanleyMilton);
        vm.serializeAddress(stanleyJson, "strategyAave", strategyAave);
        vm.serializeAddress(stanleyJson, "strategyCompound", strategyCompound);
        vm.serializeBool(stanleyJson, "stanleyIsPaused", stanleyIsPaused);
        vm.serializeUint(
            stanleyJson,
            "stanleyTotalBalance",
            stanleyTotalBalance
        );
        vm.serializeAddress(stanleyJson, "stanleyOwner", stanleyOwner);
        vm.serializeUint(
            stanleyJson,
            "strategyAaveVersion",
            strategyAaveVersion
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveAsset",
            strategyAaveAsset
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveOwner",
            strategyAaveOwner
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveShareToken",
            strategyAaveShareToken
        );
        vm.serializeUint(stanleyJson, "strategyAaveApr", strategyAaveApr);
        vm.serializeUint(
            stanleyJson,
            "strategyAaveBalance",
            strategyAaveBalance
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveStanley",
            strategyAaveStanley
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveTreasury",
            strategyAaveTreasury
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyAaveTreasuryManager",
            strategyAaveTreasuryManager
        );
        vm.serializeBool(
            stanleyJson,
            "strategyAaveIsPaused",
            strategyAaveIsPaused
        );

        vm.serializeUint(
            stanleyJson,
            "strategyCompoundVersion",
            strategyCompoundVersion
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundAsset",
            strategyCompoundAsset
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundOwner",
            strategyCompoundOwner
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundShareToken",
            strategyCompoundShareToken
        );
        vm.serializeUint(
            stanleyJson,
            "strategyCompoundApr",
            strategyCompoundApr
        );
        vm.serializeUint(
            stanleyJson,
            "strategyCompoundBalance",
            strategyCompoundBalance
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundStanley",
            strategyCompoundStanley
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundTreasury",
            strategyCompoundTreasury
        );
        vm.serializeAddress(
            stanleyJson,
            "strategyCompoundTreasuryManager",
            strategyCompoundTreasuryManager
        );
        vm.serializeBool(
            stanleyJson,
            "strategyCompoundIsPaused",
            strategyCompoundIsPaused
        );

        string memory finalJson = vm.serializeUint(
            stanleyJson,
            "blockNumber",
            blockNumber
        );
        string memory fileBlockNumber = string.concat(
            Strings.toString(blockNumber),
            ".json"
        );
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save Stanley data to json");
    }

    function assert(StanleySnapshot stanleySnapshot1, StanleySnapshot stanleySnapshot2) external {
        assertEq(stanleySnapshot1.stanleyExchangeRate(), stanleySnapshot1.stanleyExchangeRate());
        assertEq(stanleySnapshot1.stanleyAsset(), stanleySnapshot1.stanleyAsset());
        assertEq(stanleySnapshot1.stanleyMilton(), stanleySnapshot1.stanleyMilton());
        assertEq(stanleySnapshot1.strategyAave(), stanleySnapshot1.strategyAave());
        assertEq(stanleySnapshot1.strategyCompound(), stanleySnapshot1.strategyCompound());
        assertEq(stanleySnapshot1.stanleyIsPaused(), stanleySnapshot1.stanleyIsPaused());
        assertEq(stanleySnapshot1.stanleyTotalBalance(), stanleySnapshot1.stanleyTotalBalance());
        assertEq(stanleySnapshot1.stanleyOwner(), stanleySnapshot1.stanleyOwner());
        assertEq(stanleySnapshot1.strategyAaveOwner(), stanleySnapshot1.strategyAaveOwner());
        assertEq(stanleySnapshot1.strategyAaveShareToken(), stanleySnapshot1.strategyAaveShareToken());
        assertEq(stanleySnapshot1.strategyAaveApr(), stanleySnapshot1.strategyAaveApr());
        assertEq(stanleySnapshot1.strategyAaveBalance(), stanleySnapshot1.strategyAaveBalance());
        assertEq(stanleySnapshot1.strategyAaveStanley(), stanleySnapshot1.strategyAaveStanley());
        assertEq(stanleySnapshot1.strategyAaveTreasury(), stanleySnapshot1.strategyAaveTreasury());
        assertEq(stanleySnapshot1.strategyAaveTreasuryManager(), stanleySnapshot1.strategyAaveTreasuryManager());
        assertEq(stanleySnapshot1.strategyAaveIsPaused(), stanleySnapshot1.strategyAaveIsPaused());
        assertEq(stanleySnapshot1.strategyCompoundAsset(), stanleySnapshot1.strategyCompoundAsset());
        assertEq(stanleySnapshot1.strategyCompoundOwner(), stanleySnapshot1.strategyCompoundOwner());
        assertEq(stanleySnapshot1.strategyCompoundShareToken(), stanleySnapshot1.strategyCompoundShareToken());
        assertEq(stanleySnapshot1.strategyCompoundApr(), stanleySnapshot1.strategyCompoundApr());
        assertEq(stanleySnapshot1.strategyCompoundBalance(), stanleySnapshot1.strategyCompoundBalance());
        assertEq(stanleySnapshot1.strategyCompoundStanley(), stanleySnapshot1.strategyCompoundStanley());
        assertEq(stanleySnapshot1.strategyCompoundTreasury(), stanleySnapshot1.strategyCompoundTreasury());
        assertEq(stanleySnapshot1.strategyCompoundTreasuryManager(), stanleySnapshot1.strategyCompoundTreasuryManager());
        assertEq(stanleySnapshot1.strategyCompoundIsPaused(), stanleySnapshot1.strategyCompoundIsPaused());
        assertEq(stanleySnapshot1.blockNumber(), stanleySnapshot1.blockNumber());
    }

}
