// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/amm/pool/Joseph.sol";
import "forge-std/Test.sol";

contract JosephSnapshot is Script, Test {
    address private _joseph;

    address public josephAsset;
    address public josephTreasury;
    address public josephCharlieTreasuryManager;
    address public josephCharlieTreasury;
    address public josephTreasuryManager;
    address public josephOwner;
    uint256 public josephVersion;
    uint256 public josephRedeemFeeRate;
    uint256 public josephRedeemLpMaxCollateralRatio;
    uint256 public josephAmmTreasuryAssetManagementBalanceRatio;
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
        josephCharlieTreasuryManager = joseph.getCharlieTreasuryManager();
        josephCharlieTreasury = joseph.getCharlieTreasury();
        josephTreasuryManager = joseph.getTreasuryManager();
        josephOwner = joseph.owner();
        josephVersion = joseph.getVersion();
        josephRedeemFeeRate = joseph.getRedeemFeeRate();
        josephRedeemLpMaxCollateralRatio = joseph.getRedeemLpMaxCollateralRatio();
        josephAmmTreasuryAssetManagementBalanceRatio = joseph.getAmmTreasuryAssetManagementBalanceRatio();
        josephMaxLiquidityPoolBalance = joseph.getMaxLiquidityPoolBalance();
        josephMaxLpAccountContribution = joseph.getMaxLpAccountContribution();
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
        vm.serializeAddress(josephJson, "josephCharlieTreasuryManager", josephCharlieTreasuryManager);
        vm.serializeAddress(josephJson, "josephCharlieTreasury", josephCharlieTreasury);
        vm.serializeAddress(josephJson, "josephTreasuryManager", josephTreasuryManager);
        vm.serializeAddress(josephJson, "josephOwner", josephOwner);

        vm.serializeUint(josephJson, "josephVersion", josephVersion);
        vm.serializeUint(josephJson, "josephRedeemFeeRate", josephRedeemFeeRate);
        vm.serializeUint(josephJson, "josephRedeemLpMaxCollateralRatio", josephRedeemLpMaxCollateralRatio);
        vm.serializeUint(josephJson, "josephAmmTreasuryAssetManagementBalanceRatio", josephAmmTreasuryAssetManagementBalanceRatio);
        vm.serializeUint(josephJson, "josephMaxLiquidityPoolBalance", josephMaxLiquidityPoolBalance);
        vm.serializeUint(josephJson, "josephMaxLpAccountContribution", josephMaxLpAccountContribution);
        vm.serializeUint(josephJson, "josephExchangeRate", josephExchangeRate);
        vm.serializeUint(josephJson, "josephVaultReservesRatio", josephVaultReservesRatio);

        vm.serializeBool(josephJson, "josephIsPaused", josephIsPaused);

        string memory finalJson = vm.serializeUint(josephJson, "blockNumber", blockNumber);
        string memory fileBlockNumber = string.concat(Strings.toString(blockNumber), ".json");
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save Joseph data to json");
    }

    function assertJoseph(JosephSnapshot josephSnapshot1, JosephSnapshot josephSnapshot2) external {
        assertEq(josephSnapshot1.josephAsset(), josephSnapshot2.josephAsset(), "Wrong asset");
        assertEq(josephSnapshot1.josephTreasury(), josephSnapshot2.josephTreasury());
        assertEq(josephSnapshot1.josephCharlieTreasuryManager(), josephSnapshot2.josephCharlieTreasuryManager());
        assertEq(josephSnapshot1.josephCharlieTreasury(), josephSnapshot2.josephCharlieTreasury());
        assertEq(josephSnapshot1.josephTreasuryManager(), josephSnapshot2.josephTreasuryManager());
        assertEq(josephSnapshot1.josephOwner(), josephSnapshot2.josephOwner());
        assertEq(josephSnapshot1.josephRedeemFeeRate(), josephSnapshot2.josephRedeemFeeRate());
        assertEq(
            josephSnapshot1.josephRedeemLpMaxCollateralRatio(),
            josephSnapshot2.josephRedeemLpMaxCollateralRatio()
        );
        assertEq(josephSnapshot1.josephAmmTreasuryAssetManagementBalanceRatio(), josephSnapshot2.josephAmmTreasuryAssetManagementBalanceRatio());
        assertEq(josephSnapshot1.josephMaxLiquidityPoolBalance(), josephSnapshot2.josephMaxLiquidityPoolBalance());
        assertEq(josephSnapshot1.josephMaxLpAccountContribution(), josephSnapshot2.josephMaxLpAccountContribution());
        assertEq(josephSnapshot1.josephExchangeRate(), josephSnapshot2.josephExchangeRate());
        assertEq(josephSnapshot1.josephVaultReservesRatio(), josephSnapshot2.josephVaultReservesRatio());
        assertEq(josephSnapshot1.josephIsPaused(), josephSnapshot2.josephIsPaused());
        assertEq(josephSnapshot1.blockNumber(), josephSnapshot2.blockNumber());
        assertEq(josephSnapshot1.blockTimestamp(), josephSnapshot2.blockTimestamp());
    }
}
