// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/interfaces/types/MiltonStorageTypes.sol";
import "contracts/interfaces/IMiltonStorage.sol";
import "contracts/amm/MiltonStorage.sol";
import "forge-std/Test.sol";

contract MiltonStorageSnapshot is Script, Test {
    address private _miltonStorage;

    address public miltonStorageOwner;

    uint256 public miltonStorageVersion;
    uint256 public miltonStorageLastSwapId;
    uint256 public miltonStorageTotalNotionalPayFixed;
    uint256 public miltonStorageTotalNotionalReceiveFixed;

    IporTypes.MiltonBalancesMemory public miltonStorageBalance;
    MiltonStorageTypes.ExtendedBalancesMemory public miltonStorageExtendedBalance;

    //getExtendedBalance
    uint256 public extendedBalanceTotalCollateralPayFixed;
    uint256 public extendedBalanceTotalCollateralReceiveFixed;
    uint256 public extendedBalanceLiquidityPool;
    uint256 public extendedBalanceVault;
    uint256 public extendedBalanceIporPublicationFee;
    uint256 public extendedBalanceTreasury;
    //getBalance
    uint256 public totalCollateralPayFixed;
    uint256 public totalCollateralReceiveFixed;
    uint256 public liquidityPool;
    uint256 public vault;

    bool public miltonStorageIsPaused;
    uint256 public blockNumber;
    uint256 public blockTimestamp;

    constructor(address miltonStorage) {
        _miltonStorage = miltonStorage;
    }

    function snapshot() public {
        MiltonStorage miltonStorage = MiltonStorage(_miltonStorage);

        miltonStorageOwner = miltonStorage.owner();

        miltonStorageVersion = miltonStorage.getVersion();
        miltonStorageLastSwapId = miltonStorage.getLastSwapId();

        miltonStorageExtendedBalance = miltonStorage.getExtendedBalance();
        extendedBalanceTotalCollateralPayFixed = miltonStorageExtendedBalance.totalCollateralPayFixed;
        extendedBalanceTotalCollateralReceiveFixed = miltonStorageExtendedBalance.totalCollateralReceiveFixed;
        extendedBalanceLiquidityPool = miltonStorageExtendedBalance.liquidityPool;
        extendedBalanceVault = miltonStorageExtendedBalance.vault;
        extendedBalanceIporPublicationFee = miltonStorageExtendedBalance.iporPublicationFee;
        extendedBalanceTreasury = miltonStorageExtendedBalance.treasury;

        miltonStorageBalance = miltonStorage.getBalance();
        totalCollateralPayFixed = miltonStorageBalance.totalCollateralPayFixed;
        totalCollateralReceiveFixed = miltonStorageBalance.totalCollateralReceiveFixed;
        liquidityPool = miltonStorageBalance.liquidityPool;
        vault = miltonStorageBalance.vault;

        (miltonStorageTotalNotionalPayFixed, miltonStorageTotalNotionalReceiveFixed) = miltonStorage
            .getTotalOutstandingNotional();

        miltonStorageIsPaused = miltonStorage.paused();

        blockNumber = block.number;
        blockTimestamp = block.timestamp;
    }

    function toJson(string memory fileName) external {
        console2.log("START: Save MiltonStorage data to json");

        string memory path = vm.projectRoot();
        string memory miltonStorageJson = "";

        vm.serializeAddress(miltonStorageJson, "miltonStorageOwner", miltonStorageOwner);

        vm.serializeUint(miltonStorageJson, "miltonStorageVersion", miltonStorageVersion);
        vm.serializeUint(miltonStorageJson, "miltonStorageLastSwapId", miltonStorageLastSwapId);
        vm.serializeUint(miltonStorageJson, "miltonStorageTotalNotionalPayFixed", miltonStorageTotalNotionalPayFixed);
        vm.serializeUint(
            miltonStorageJson,
            "miltonStorageTotalNotionalReceiveFixed",
            miltonStorageTotalNotionalReceiveFixed
        );
        vm.serializeUint(miltonStorageJson, "totalCollateralPayFixed", totalCollateralPayFixed);

        vm.serializeUint(miltonStorageJson, "totalCollateralReceiveFixed", totalCollateralReceiveFixed);
        vm.serializeUint(miltonStorageJson, "liquidityPool", liquidityPool);
        vm.serializeUint(miltonStorageJson, "vault", vault);
        vm.serializeUint(
            miltonStorageJson,
            "extendedBalanceTotalCollateralPayFixed",
            extendedBalanceTotalCollateralPayFixed
        );
        vm.serializeUint(
            miltonStorageJson,
            "extendedBalanceTotalCollateralReceiveFixed",
            extendedBalanceTotalCollateralReceiveFixed
        );
        vm.serializeUint(miltonStorageJson, "extendedBalanceLiquidityPool", extendedBalanceLiquidityPool);
        vm.serializeUint(miltonStorageJson, "extendedBalanceVault", extendedBalanceVault);
        vm.serializeUint(miltonStorageJson, "extendedBalanceIporPublicationFee", extendedBalanceIporPublicationFee);
        vm.serializeUint(miltonStorageJson, "extendedBalanceTreasury", extendedBalanceTreasury);
        vm.serializeBool(miltonStorageJson, "miltonStorageIsPaused", miltonStorageIsPaused);

        string memory finalJson = vm.serializeUint(miltonStorageJson, "blockNumber", blockNumber);
        string memory fileBlockNumber = string.concat(Strings.toString(blockNumber), ".json");
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save MiltonStorage data to json");
    }

    function assertMilton(MiltonStorageSnapshot miltonStorageSnapshot1, MiltonStorageSnapshot miltonStorageSnapshot2)
        external
    {
        assertEq(
            miltonStorageSnapshot1.miltonStorageOwner(),
            miltonStorageSnapshot2.miltonStorageOwner(),
            "MiltonStorage: Milton Storage Owner should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.miltonStorageLastSwapId(),
            miltonStorageSnapshot2.miltonStorageLastSwapId(),
            "MiltonStorage: Milton Storage Last Swap ID should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.miltonStorageTotalNotionalPayFixed(),
            miltonStorageSnapshot2.miltonStorageTotalNotionalPayFixed(),
            "MiltonStorage: Milton Storage Total Notional Pay Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.miltonStorageTotalNotionalReceiveFixed(),
            miltonStorageSnapshot2.miltonStorageTotalNotionalReceiveFixed(),
            "MiltonStorage: Milton Storage Total Notional Receive Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceTotalCollateralPayFixed(),
            miltonStorageSnapshot2.extendedBalanceTotalCollateralPayFixed(),
            "MiltonStorage: Extended Balance Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceTotalCollateralReceiveFixed(),
            miltonStorageSnapshot2.extendedBalanceTotalCollateralReceiveFixed(),
            "MiltonStorage: Extended Balance Total Collateral Receive Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceLiquidityPool(),
            miltonStorageSnapshot2.extendedBalanceLiquidityPool(),
            "MiltonStorage: Extended Balance Liquidity Pool should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceVault(),
            miltonStorageSnapshot2.extendedBalanceVault(),
            "MiltonStorage: Extended Balance Vault should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceIporPublicationFee(),
            miltonStorageSnapshot2.extendedBalanceIporPublicationFee(),
            "MiltonStorage: Extended Balance IPOR Publication Fee should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.extendedBalanceTreasury(),
            miltonStorageSnapshot2.extendedBalanceTreasury(),
            "MiltonStorage: Extended Balance Treasury should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.totalCollateralPayFixed(),
            miltonStorageSnapshot2.totalCollateralPayFixed(),
            "MiltonStorage: Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.totalCollateralReceiveFixed(),
            miltonStorageSnapshot2.totalCollateralReceiveFixed(),
            "MiltonStorage: Total Collateral Receive Fixed should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.liquidityPool(),
            miltonStorageSnapshot2.liquidityPool(),
            "MiltonStorage: Liquidity Pool should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.vault(),
            miltonStorageSnapshot2.vault(),
            "MiltonStorage: Vault should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.miltonStorageIsPaused(),
            miltonStorageSnapshot2.miltonStorageIsPaused(),
            "MiltonStorage: Milton Storage Is Paused should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.blockNumber(),
            miltonStorageSnapshot2.blockNumber(),
            "MiltonStorage: Block Number should be the same"
        );
        assertEq(
            miltonStorageSnapshot1.blockTimestamp(),
            miltonStorageSnapshot2.blockTimestamp(),
            "MiltonStorage: Block Timestamp should be the same"
        );
    }
}
