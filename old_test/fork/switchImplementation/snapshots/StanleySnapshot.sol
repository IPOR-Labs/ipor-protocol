// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ipor-protocol/contracts/vault/AssetManagement.sol";
import "@ipor-protocol/contracts/vault/strategies/StrategyCore.sol";
import "forge-std/Test.sol";

contract AssetManagementSnapshot is Script, Test {
    address private _assetManagement;
    uint256 public assetManagementVersion;
    uint256 public assetManagementExchangeRate;
    address public assetManagementAsset;
    address public assetManagementAmmTreasury;
    address public strategyAave;
    address public strategyCompound;
    bool public assetManagementIsPaused;
    uint256 public assetManagementTotalBalance;
    address public assetManagementOwner;
    uint256 public strategyAaveVersion;
    address public strategyAaveAsset;
    address public strategyAaveOwner;
    address public strategyAaveShareToken;
    uint256 public strategyAaveApy;
    uint256 public strategyAaveBalance;
    address public strategyAaveAssetManagement;
    address public strategyAaveTreasury;
    address public strategyAaveTreasuryManager;
    bool public strategyAaveIsPaused;

    uint256 public strategyCompoundVersion;
    address public strategyCompoundAsset;
    address public strategyCompoundOwner;
    address public strategyCompoundShareToken;
    uint256 public strategyCompoundApy;
    uint256 public strategyCompoundBalance;
    address public strategyCompoundAssetManagement;
    address public strategyCompoundTreasury;
    address public strategyCompoundTreasuryManager;
    bool public strategyCompoundIsPaused;

    uint256 public blockNumber;

    constructor(address assetManagement) {
        _assetManagement = assetManagement;
    }

    function snapshot() public {
        AssetManagement assetManagement = AssetManagement(_assetManagement);

        assetManagementVersion = assetManagement.getVersion();
        assetManagementAsset = assetManagement.getAsset();
        assetManagementAmmTreasury = assetManagement.getAmmTreasury();
        strategyAave = assetManagement.getStrategyAave();
        strategyCompound = assetManagement.getStrategyCompound();
        assetManagementIsPaused = assetManagement.paused();
        assetManagementOwner = assetManagement.owner();
        assetManagementTotalBalance = assetManagement.totalBalance(assetManagementAmmTreasury);
        assetManagementExchangeRate = assetManagement.calculateExchangeRate();
        StrategyCore aaveStrategy = StrategyCore(strategyAave);
        strategyAaveVersion = aaveStrategy.getVersion();
        strategyAaveAsset = aaveStrategy.getAsset();
        strategyAaveOwner = aaveStrategy.owner();
        strategyAaveShareToken = aaveStrategy.getShareToken();
        strategyAaveApy = aaveStrategy.getApy();
        strategyAaveBalance = aaveStrategy.balanceOf();
        strategyAaveAssetManagement = aaveStrategy.getAssetManagement();
        strategyAaveTreasury = aaveStrategy.getTreasury();
        strategyAaveTreasuryManager = aaveStrategy.getTreasuryManager();
        strategyAaveIsPaused = aaveStrategy.paused();

        StrategyCore compoundStrategy = StrategyCore(strategyCompound);
        strategyCompoundVersion = compoundStrategy.getVersion();
        strategyCompoundAsset = compoundStrategy.getAsset();
        strategyCompoundOwner = compoundStrategy.owner();
        strategyCompoundShareToken = compoundStrategy.getShareToken();
        strategyCompoundApy = compoundStrategy.getApy();
        strategyCompoundBalance = compoundStrategy.balanceOf();
        strategyCompoundAssetManagement = compoundStrategy.getAssetManagement();
        strategyCompoundTreasury = compoundStrategy.getTreasury();
        strategyCompoundTreasuryManager = compoundStrategy.getTreasuryManager();
        strategyCompoundIsPaused = compoundStrategy.paused();

        blockNumber = block.number;
    }

    function toJson(string memory fileName) external {
        console2.log("START: Save AssetManagement data to json");
        string memory path = vm.projectRoot();
        string memory assetManagementJson = "";
        vm.serializeUint(assetManagementJson, "assetManagementVersion", assetManagementVersion);
        vm.serializeUint(assetManagementJson, "assetManagementExchangeRate", assetManagementExchangeRate);
        vm.serializeAddress(assetManagementJson, "assetManagementAsset", assetManagementAsset);
        vm.serializeAddress(assetManagementJson, "assetManagementAmmTreasury", assetManagementAmmTreasury);
        vm.serializeAddress(assetManagementJson, "strategyAave", strategyAave);
        vm.serializeAddress(assetManagementJson, "strategyCompound", strategyCompound);
        vm.serializeBool(assetManagementJson, "assetManagementIsPaused", assetManagementIsPaused);
        vm.serializeUint(assetManagementJson, "assetManagementTotalBalance", assetManagementTotalBalance);
        vm.serializeAddress(assetManagementJson, "assetManagementOwner", assetManagementOwner);
        vm.serializeUint(assetManagementJson, "strategyAaveVersion", strategyAaveVersion);
        vm.serializeAddress(assetManagementJson, "strategyAaveAsset", strategyAaveAsset);
        vm.serializeAddress(assetManagementJson, "strategyAaveOwner", strategyAaveOwner);
        vm.serializeAddress(assetManagementJson, "strategyAaveShareToken", strategyAaveShareToken);
        vm.serializeUint(assetManagementJson, "strategyAaveApy", strategyAaveApy);
        vm.serializeUint(assetManagementJson, "strategyAaveBalance", strategyAaveBalance);
        vm.serializeAddress(assetManagementJson, "strategyAaveAssetManagement", strategyAaveAssetManagement);
        vm.serializeAddress(assetManagementJson, "strategyAaveTreasury", strategyAaveTreasury);
        vm.serializeAddress(assetManagementJson, "strategyAaveTreasuryManager", strategyAaveTreasuryManager);
        vm.serializeBool(assetManagementJson, "strategyAaveIsPaused", strategyAaveIsPaused);

        vm.serializeUint(assetManagementJson, "strategyCompoundVersion", strategyCompoundVersion);
        vm.serializeAddress(assetManagementJson, "strategyCompoundAsset", strategyCompoundAsset);
        vm.serializeAddress(assetManagementJson, "strategyCompoundOwner", strategyCompoundOwner);
        vm.serializeAddress(assetManagementJson, "strategyCompoundShareToken", strategyCompoundShareToken);
        vm.serializeUint(assetManagementJson, "strategyCompoundApy", strategyCompoundApy);
        vm.serializeUint(assetManagementJson, "strategyCompoundBalance", strategyCompoundBalance);
        vm.serializeAddress(assetManagementJson, "strategyCompoundAssetManagement", strategyCompoundAssetManagement);
        vm.serializeAddress(assetManagementJson, "strategyCompoundTreasury", strategyCompoundTreasury);
        vm.serializeAddress(assetManagementJson, "strategyCompoundTreasuryManager", strategyCompoundTreasuryManager);
        vm.serializeBool(assetManagementJson, "strategyCompoundIsPaused", strategyCompoundIsPaused);

        string memory finalJson = vm.serializeUint(assetManagementJson, "blockNumber", blockNumber);
        string memory fileBlockNumber = string.concat(Strings.toString(blockNumber), ".json");
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save AssetManagement data to json");
    }

    function assertAssetManagement(AssetManagementSnapshot assetManagementSnapshot1, AssetManagementSnapshot assetManagementSnapshot2) external {
        assertEq(assetManagementSnapshot1.assetManagementExchangeRate(), assetManagementSnapshot1.assetManagementExchangeRate());
        assertEq(assetManagementSnapshot1.assetManagementAsset(), assetManagementSnapshot1.assetManagementAsset());
        assertEq(assetManagementSnapshot1.assetManagementAmmTreasury(), assetManagementSnapshot1.assetManagementAmmTreasury());
        assertEq(assetManagementSnapshot1.strategyAave(), assetManagementSnapshot1.strategyAave());
        assertEq(assetManagementSnapshot1.strategyCompound(), assetManagementSnapshot1.strategyCompound());
        assertEq(assetManagementSnapshot1.assetManagementIsPaused(), assetManagementSnapshot1.assetManagementIsPaused());
        assertEq(assetManagementSnapshot1.assetManagementTotalBalance(), assetManagementSnapshot1.assetManagementTotalBalance());
        assertEq(assetManagementSnapshot1.assetManagementOwner(), assetManagementSnapshot1.assetManagementOwner());
        assertEq(assetManagementSnapshot1.strategyAaveOwner(), assetManagementSnapshot1.strategyAaveOwner());
        assertEq(assetManagementSnapshot1.strategyAaveShareToken(), assetManagementSnapshot1.strategyAaveShareToken());
        assertEq(assetManagementSnapshot1.strategyAaveApy(), assetManagementSnapshot1.strategyAaveApy());
        assertEq(assetManagementSnapshot1.strategyAaveBalance(), assetManagementSnapshot1.strategyAaveBalance());
        assertEq(assetManagementSnapshot1.strategyAaveAssetManagement(), assetManagementSnapshot1.strategyAaveAssetManagement());
        assertEq(assetManagementSnapshot1.strategyAaveTreasury(), assetManagementSnapshot1.strategyAaveTreasury());
        assertEq(assetManagementSnapshot1.strategyAaveTreasuryManager(), assetManagementSnapshot1.strategyAaveTreasuryManager());
        assertEq(assetManagementSnapshot1.strategyAaveIsPaused(), assetManagementSnapshot1.strategyAaveIsPaused());
        assertEq(assetManagementSnapshot1.strategyCompoundAsset(), assetManagementSnapshot1.strategyCompoundAsset());
        assertEq(assetManagementSnapshot1.strategyCompoundOwner(), assetManagementSnapshot1.strategyCompoundOwner());
        assertEq(assetManagementSnapshot1.strategyCompoundShareToken(), assetManagementSnapshot1.strategyCompoundShareToken());
        assertEq(assetManagementSnapshot1.strategyCompoundApy(), assetManagementSnapshot1.strategyCompoundApy());
        assertEq(assetManagementSnapshot1.strategyCompoundBalance(), assetManagementSnapshot1.strategyCompoundBalance());
        assertEq(assetManagementSnapshot1.strategyCompoundAssetManagement(), assetManagementSnapshot1.strategyCompoundAssetManagement());
        assertEq(assetManagementSnapshot1.strategyCompoundTreasury(), assetManagementSnapshot1.strategyCompoundTreasury());
        assertEq(
            assetManagementSnapshot1.strategyCompoundTreasuryManager(),
            assetManagementSnapshot1.strategyCompoundTreasuryManager()
        );
        assertEq(assetManagementSnapshot1.strategyCompoundIsPaused(), assetManagementSnapshot1.strategyCompoundIsPaused());
        assertEq(assetManagementSnapshot1.blockNumber(), assetManagementSnapshot1.blockNumber());
    }
}
