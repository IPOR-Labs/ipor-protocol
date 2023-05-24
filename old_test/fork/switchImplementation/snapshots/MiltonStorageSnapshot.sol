// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/amm/AmmStorage.sol";
import "forge-std/Test.sol";

contract AmmStorageSnapshot is Script, Test {
    address private _ammStorage;

    address public ammStorageOwner;

    uint256 public ammStorageVersion;
    uint256 public ammStorageLastSwapId;
    uint256 public ammStorageTotalNotionalPayFixed;
    uint256 public ammStorageTotalNotionalReceiveFixed;

    IporTypes.AmmBalancesMemory public ammStorageBalance;
    AmmStorageTypes.ExtendedBalancesMemory public ammStorageExtendedBalance;

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

    bool public ammStorageIsPaused;
    uint256 public blockNumber;
    uint256 public blockTimestamp;

    constructor(address ammStorage) {
        _ammStorage = ammStorage;
    }

    function snapshot() public {
        AmmStorage ammStorage = AmmStorage(_ammStorage);

        ammStorageOwner = ammStorage.owner();

        ammStorageVersion = ammStorage.getVersion();
        ammStorageLastSwapId = ammStorage.getLastSwapId();

        ammStorageExtendedBalance = ammStorage.getExtendedBalance();
        extendedBalanceTotalCollateralPayFixed = ammStorageExtendedBalance.totalCollateralPayFixed;
        extendedBalanceTotalCollateralReceiveFixed = ammStorageExtendedBalance.totalCollateralReceiveFixed;
        extendedBalanceLiquidityPool = ammStorageExtendedBalance.liquidityPool;
        extendedBalanceVault = ammStorageExtendedBalance.vault;
        extendedBalanceIporPublicationFee = ammStorageExtendedBalance.iporPublicationFee;
        extendedBalanceTreasury = ammStorageExtendedBalance.treasury;

        ammStorageBalance = ammStorage.getBalance();
        totalCollateralPayFixed = ammStorageBalance.totalCollateralPayFixed;
        totalCollateralReceiveFixed = ammStorageBalance.totalCollateralReceiveFixed;
        liquidityPool = ammStorageBalance.liquidityPool;
        vault = ammStorageBalance.vault;

        (ammStorageTotalNotionalPayFixed, ammStorageTotalNotionalReceiveFixed) = ammStorage
            .getTotalOutstandingNotional();

        ammStorageIsPaused = ammStorage.paused();

        blockNumber = block.number;
        blockTimestamp = block.timestamp;
    }

    function toJson(string memory fileName) external {
        console2.log("START: Save AmmStorage data to json");

        string memory path = vm.projectRoot();
        string memory ammStorageJson = "";

        vm.serializeAddress(ammStorageJson, "ammStorageOwner", ammStorageOwner);

        vm.serializeUint(ammStorageJson, "ammStorageVersion", ammStorageVersion);
        vm.serializeUint(ammStorageJson, "ammStorageLastSwapId", ammStorageLastSwapId);
        vm.serializeUint(ammStorageJson, "ammStorageTotalNotionalPayFixed", ammStorageTotalNotionalPayFixed);
        vm.serializeUint(
            ammStorageJson,
            "ammStorageTotalNotionalReceiveFixed",
            ammStorageTotalNotionalReceiveFixed
        );
        vm.serializeUint(ammStorageJson, "totalCollateralPayFixed", totalCollateralPayFixed);

        vm.serializeUint(ammStorageJson, "totalCollateralReceiveFixed", totalCollateralReceiveFixed);
        vm.serializeUint(ammStorageJson, "liquidityPool", liquidityPool);
        vm.serializeUint(ammStorageJson, "vault", vault);
        vm.serializeUint(
            ammStorageJson,
            "extendedBalanceTotalCollateralPayFixed",
            extendedBalanceTotalCollateralPayFixed
        );
        vm.serializeUint(
            ammStorageJson,
            "extendedBalanceTotalCollateralReceiveFixed",
            extendedBalanceTotalCollateralReceiveFixed
        );
        vm.serializeUint(ammStorageJson, "extendedBalanceLiquidityPool", extendedBalanceLiquidityPool);
        vm.serializeUint(ammStorageJson, "extendedBalanceVault", extendedBalanceVault);
        vm.serializeUint(ammStorageJson, "extendedBalanceIporPublicationFee", extendedBalanceIporPublicationFee);
        vm.serializeUint(ammStorageJson, "extendedBalanceTreasury", extendedBalanceTreasury);
        vm.serializeBool(ammStorageJson, "ammStorageIsPaused", ammStorageIsPaused);

        string memory finalJson = vm.serializeUint(ammStorageJson, "blockNumber", blockNumber);
        string memory fileBlockNumber = string.concat(Strings.toString(blockNumber), ".json");
        string memory finalFileName = string.concat(fileName, fileBlockNumber);
        vm.writeJson(finalJson, string.concat(path, finalFileName));
        console2.log("END: Save AmmStorage data to json");
    }

    function assertAmmTreasury(AmmStorageSnapshot ammStorageSnapshot1, AmmStorageSnapshot ammStorageSnapshot2)
        external
    {
        assertEq(
            ammStorageSnapshot1.ammStorageOwner(),
            ammStorageSnapshot2.ammStorageOwner(),
            "AmmStorage: AmmTreasury Storage Owner should be the same"
        );
        assertEq(
            ammStorageSnapshot1.ammStorageLastSwapId(),
            ammStorageSnapshot2.ammStorageLastSwapId(),
            "AmmStorage: AmmTreasury Storage Last Swap ID should be the same"
        );
        assertEq(
            ammStorageSnapshot1.ammStorageTotalNotionalPayFixed(),
            ammStorageSnapshot2.ammStorageTotalNotionalPayFixed(),
            "AmmStorage: AmmTreasury Storage Total Notional Pay Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.ammStorageTotalNotionalReceiveFixed(),
            ammStorageSnapshot2.ammStorageTotalNotionalReceiveFixed(),
            "AmmStorage: AmmTreasury Storage Total Notional Receive Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceTotalCollateralPayFixed(),
            ammStorageSnapshot2.extendedBalanceTotalCollateralPayFixed(),
            "AmmStorage: Extended Balance Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceTotalCollateralReceiveFixed(),
            ammStorageSnapshot2.extendedBalanceTotalCollateralReceiveFixed(),
            "AmmStorage: Extended Balance Total Collateral Receive Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceLiquidityPool(),
            ammStorageSnapshot2.extendedBalanceLiquidityPool(),
            "AmmStorage: Extended Balance Liquidity Pool should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceVault(),
            ammStorageSnapshot2.extendedBalanceVault(),
            "AmmStorage: Extended Balance Vault should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceIporPublicationFee(),
            ammStorageSnapshot2.extendedBalanceIporPublicationFee(),
            "AmmStorage: Extended Balance IPOR Publication Fee should be the same"
        );
        assertEq(
            ammStorageSnapshot1.extendedBalanceTreasury(),
            ammStorageSnapshot2.extendedBalanceTreasury(),
            "AmmStorage: Extended Balance Treasury should be the same"
        );
        assertEq(
            ammStorageSnapshot1.totalCollateralPayFixed(),
            ammStorageSnapshot2.totalCollateralPayFixed(),
            "AmmStorage: Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.totalCollateralReceiveFixed(),
            ammStorageSnapshot2.totalCollateralReceiveFixed(),
            "AmmStorage: Total Collateral Receive Fixed should be the same"
        );
        assertEq(
            ammStorageSnapshot1.liquidityPool(),
            ammStorageSnapshot2.liquidityPool(),
            "AmmStorage: Liquidity Pool should be the same"
        );
        assertEq(
            ammStorageSnapshot1.vault(),
            ammStorageSnapshot2.vault(),
            "AmmStorage: Vault should be the same"
        );
        assertEq(
            ammStorageSnapshot1.ammStorageIsPaused(),
            ammStorageSnapshot2.ammStorageIsPaused(),
            "AmmStorage: AmmTreasury Storage Is Paused should be the same"
        );
        assertEq(
            ammStorageSnapshot1.blockNumber(),
            ammStorageSnapshot2.blockNumber(),
            "AmmStorage: Block Number should be the same"
        );
        assertEq(
            ammStorageSnapshot1.blockTimestamp(),
            ammStorageSnapshot2.blockTimestamp(),
            "AmmStorage: Block Timestamp should be the same"
        );
    }
}
