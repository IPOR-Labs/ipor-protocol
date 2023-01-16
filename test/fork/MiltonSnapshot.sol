// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/amm/Milton.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";

contract MiltonSnapshot is Script {
    using stdJson for string;
    address private _milton;
    address public miltonJoseph;
    address public miltonSpreadModel;
    address public miltonAsset;
    address public miltonOwner;
    address public miltonFacadeDataProviderOwner;
    uint256 public miltonVersion;
    uint256 public miltonFacadeDataProviderVersion;
    uint256 public miltonMaxSwapCollateralAmount;
    uint256 public miltonMaxLpUtilizationRate;
    uint256 public miltonMaxLpUtilizationPerLegRate;
    uint256 public miltonIncomeFeeRate;
    uint256 public miltonOpeningFeeRate;
    uint256 public miltonOpeningFeeTreasuryPortionRate;
    uint256 public miltonIporPublicationFee;
    uint256 public miltonLiquidationDepositAmount;
    uint256 public miltonWadLiquidationDepositAmount;
    uint256 public miltonMaxLeverage;
    uint256 public miltonMinLeverage;
    int256 public miltonSpreadPayFixed;
    int256 public miltonSpreadReceiveFixed;
    int256 public miltonSoapPayFixed;
    int256 public miltonSoapReceiveFixed;
    int256 public miltonSoap;
    uint256 public totalCollateralPayFixed;
    uint256 public totalCollateralReceiveFixed;
    uint256 public liquidityPool;
    uint256 public vault;
    bool public miltonIsPaused;
    uint256 public blockNumber;
    uint256 public blockTimestamp;

    constructor(address milton) {
        _milton = milton;
    }

    function snapshot() public {
        Milton milton = Milton(_milton);
        MiltonFacadeDataProvider miltonFacadeDataProvider = MiltonFacadeDataProvider(
            _milton
        );

        miltonJoseph = milton.getJoseph();
        miltonSpreadModel = milton.getMiltonSpreadModel();
        miltonAsset = milton.getAsset();
        miltonOwner = milton.owner();
        miltonFacadeDataProviderOwner = miltonFacadeDataProvider.owner();

        miltonVersion = milton.getVersion();
        miltonFacadeDataProviderVersion = miltonFacadeDataProvider.getVersion();
        miltonMaxSwapCollateralAmount = milton
        .getMaxSwapCollateralAmount();
        miltonMaxLpUtilizationRate = milton.getMaxLpUtilizationRate();
        miltonMaxLpUtilizationPerLegRate = milton
        .getMaxLpUtilizationPerLegRate();
        miltonIncomeFeeRate = milton.getIncomeFeeRate();
        miltonOpeningFeeRate = milton.getOpeningFeeRate();
        miltonOpeningFeeTreasuryPortionRate = milton
        .getOpeningFeeTreasuryPortionRate();
        miltonIporPublicationFee = milton.getIporPublicationFee();
        miltonLiquidationDepositAmount = milton
        .getLiquidationDepositAmount();
        miltonWadLiquidationDepositAmount = milton
        .getWadLiquidationDepositAmount();
        miltonMaxLeverage = milton.getMaxLeverage();
        miltonMinLeverage = milton.getMinLeverage();

        (miltonSpreadPayFixed, miltonSpreadReceiveFixed) = milton
        .calculateSpread();
        (miltonSoapPayFixed, miltonSoapReceiveFixed, miltonSoap) = milton
        .calculateSoap();

        IporTypes.MiltonBalancesMemory memory miltonAccruedBalance = milton.getAccruedBalance();
        totalCollateralPayFixed = miltonAccruedBalance.totalCollateralPayFixed;
        totalCollateralReceiveFixed = miltonAccruedBalance.totalCollateralReceiveFixed;
        liquidityPool = miltonAccruedBalance.liquidityPool;
        vault = miltonAccruedBalance.vault;

        blockNumber = block.number;
        blockTimestamp = block.timestamp;
    }

    function toJson(string memory fileName) external {
        string memory path = vm.projectRoot();
        string memory miltonJson = "";

        vm.serializeAddress(miltonJson, "milton", _milton);
        vm.serializeAddress(miltonJson, "miltonJoseph", miltonJoseph);
        vm.serializeAddress(miltonJson, "miltonSpreadModel", miltonSpreadModel);
        vm.serializeAddress(miltonJson, "miltonAsset", miltonAsset);
        vm.serializeAddress(miltonJson, "miltonOwner", miltonOwner);
        vm.serializeAddress(
            miltonJson,
            "miltonFacadeDataProviderOwner",
            miltonFacadeDataProviderOwner
        );

        vm.serializeUint(miltonJson, "miltonVersion", miltonVersion);
        vm.serializeUint(
            miltonJson,
            "miltonFacadeDataProviderVersion",
            miltonFacadeDataProviderVersion
        );
        vm.serializeUint(
            miltonJson,
            "miltonMaxSwapCollateralAmount",
            miltonMaxSwapCollateralAmount
        );
        vm.serializeUint(
            miltonJson,
            "miltonMaxLpUtilizationRate",
            miltonMaxLpUtilizationRate
        );
        vm.serializeUint(
            miltonJson,
            "miltonMaxLpUtilizationPerLegRate",
            miltonMaxLpUtilizationPerLegRate
        );
        vm.serializeUint(
            miltonJson,
            "miltonIncomeFeeRate",
            miltonIncomeFeeRate
        );
        vm.serializeUint(
            miltonJson,
            "miltonOpeningFeeRate",
            miltonOpeningFeeRate
        );
        vm.serializeUint(
            miltonJson,
            "miltonOpeningFeeTreasuryPortionRate",
            miltonOpeningFeeTreasuryPortionRate
        );
        vm.serializeUint(
            miltonJson,
            "miltonIporPublicationFee",
            miltonIporPublicationFee
        );
        vm.serializeUint(
            miltonJson,
            "miltonLiquidationDepositAmount",
            miltonLiquidationDepositAmount
        );
        vm.serializeUint(
            miltonJson,
            "miltonWadLiquidationDepositAmount",
            miltonWadLiquidationDepositAmount
        );
        vm.serializeUint(miltonJson, "miltonMaxLeverage", miltonMaxLeverage);
        vm.serializeUint(miltonJson, "miltonMinLeverage", miltonMinLeverage);

        vm.serializeInt(
            miltonJson,
            "miltonSpreadPayFixed",
            miltonSpreadPayFixed
        );
        vm.serializeInt(
            miltonJson,
            "miltonSpreadReceiveFixed",
            miltonSpreadReceiveFixed
        );
        vm.serializeInt(miltonJson, "miltonSoapPayFixed", miltonSoapPayFixed);
        vm.serializeInt(
            miltonJson,
            "miltonSoapReceiveFixed",
            miltonSoapReceiveFixed
        );
        vm.serializeInt(miltonJson, "miltonSoap", miltonSoap);

        vm.serializeUint(
            miltonJson,
            "totalCollateralPayFixed",
            totalCollateralPayFixed
        );
        vm.serializeUint(
            miltonJson,
            "totalCollateralReceiveFixed",
            totalCollateralReceiveFixed
        );
        vm.serializeUint(
            miltonJson,
            "liquidityPool",
            liquidityPool
        );
        vm.serializeUint(
            miltonJson,
            "vault",
            vault
        );

        vm.serializeBool(miltonJson, "miltonIsPaused", miltonIsPaused);
        vm.serializeUint(miltonJson, "blockNumber", blockNumber);

        string memory finalJson = vm.serializeUint(
            miltonJson,
            "blockTimestamp",
            blockTimestamp
        );
        vm.writeJson(finalJson, string.concat(path, fileName));
    }

    function fromJson(string memory fileName) public {
//        TODO: fix problem with reading json
//        string memory path = vm.projectRoot();
//        console2.log("path", path);
//        string memory pathToFile = string.concat(path, fileName);
//        console2.log("pathToFile", pathToFile);
//        string memory data = vm.readFile(pathToFile);
////
//        _milton = data.readAddress("milton");
////        miltonJoseph = data.readAddress("miltonJoseph");
////        miltonVersion = data.readString("miltonVersion");
////        miltonSpreadModel = data.readAddress("miltonSpreadModel");
////        miltonAsset = data.readAddress("miltonAsset");
////        miltonOwner = data.readAddress("miltonOwner");
////        miltonFacadeDataProviderOwner = data.readAddress("miltonFacadeDataProviderOwner");
////        miltonFacadeDataProviderVersion = data.readUint("miltonFacadeDataProviderVersion");
////        miltonMaxSwapCollateralAmount = data.readUint("miltonMaxSwapCollateralAmount");
////        miltonMaxLpUtilizationRate = data.readUint(
////            "miltonMaxLpUtilizationRate"
////        );
////        miltonMaxLpUtilizationPerLegRate = data.readUint(
////            "miltonMaxLpUtilizationPerLegRate"
////        );
////        miltonIncomeFeeRate = data.readUint(
////            "miltonIncomeFeeRate"
////        );
////        miltonOpeningFeeRate = data.readUint(
////            "miltonOpeningFeeRate"
////        );
////        miltonOpeningFeeTreasuryPortionRate = data.readUint(
////            "miltonOpeningFeeTreasuryPortionRate"
////        );
////        miltonIporPublicationFee = data.readUint(
////            "miltonIporPublicationFee"
////        );
////
////        miltonLiquidationDepositAmount = data.readUint(
////            "miltonLiquidationDepositAmount"
////        );
////        miltonWadLiquidationDepositAmount = data.readUint(
////            "miltonWadLiquidationDepositAmount"
////        );
////        miltonMaxLeverage = data.readUint(
////            "miltonMaxLeverage"
////        );
////        miltonMinLeverage = data.readUint(
////            "miltonMinLeverage"
////        );
////        miltonSpreadPayFixed = data.readInt(
////            "miltonSpreadPayFixed"
////        );
////        miltonSpreadReceiveFixed = data.readInt(
////            "miltonSpreadReceiveFixed"
////        );
////        miltonSoapPayFixed = data.readInt(
////            "miltonSoapPayFixed");
////
////        totalCollateralPayFixed = data.readUint("totalCollateralPayFixed");
////        totalCollateralReceiveFixed = data.readUint("totalCollateralReceiveFixed");
////        liquidityPool = data.readUint("liquidityPool");
//        console2.log( data.readString("vault"));
////        miltonIsPaused = data.readBool("miltonIsPaused");
    }

    function consoleLog() public {
        console2.log("milton", _milton);
        console2.log("miltonJoseph", miltonJoseph);
        console2.log("miltonSpreadModel", miltonSpreadModel);
        console2.log("miltonAsset", miltonAsset);
        console2.log("miltonOwner", miltonOwner);
        console2.log("miltonVersion", miltonVersion);
        console2.log("miltonFacadeDataProviderVersion", miltonFacadeDataProviderVersion);
        console2.log("miltonMaxSwapCollateralAmount", miltonMaxSwapCollateralAmount);
        console2.log("miltonMaxLpUtilizationRate", miltonMaxLpUtilizationRate);
        console2.log("miltonMaxLpUtilizationPerLegRate", miltonMaxLpUtilizationPerLegRate);
        console2.log("miltonIncomeFeeRate", miltonIncomeFeeRate);
        console2.log("miltonOpeningFeeRate", miltonOpeningFeeRate);
        console2.log("miltonOpeningFeeTreasuryPortionRate", miltonOpeningFeeTreasuryPortionRate);
        console2.log("miltonIporPublicationFee", miltonIporPublicationFee);
        console2.log("miltonLiquidationDepositAmount", miltonLiquidationDepositAmount);
        console2.log("miltonWadLiquidationDepositAmount", miltonWadLiquidationDepositAmount);
        console2.log("miltonMaxLeverage", miltonMaxLeverage);
        console2.log("miltonMinLeverage", miltonMinLeverage);
        console2.logInt(miltonSpreadPayFixed);
        console2.logInt(miltonSpreadReceiveFixed);
        console2.logInt(miltonSoapPayFixed);
        console2.logInt(miltonSoapReceiveFixed);
        console2.logInt( miltonSoap);
        console2.log("totalCollateralPayFixed", totalCollateralPayFixed);
        console2.log("totalCollateralReceiveFixed", totalCollateralReceiveFixed);
        console2.log("liquidityPool", liquidityPool);
        console2.log("vault", vault);
        console2.log("blockNumber", blockNumber);
        console2.log("miltonIsPaused", miltonIsPaused);
        console2.log("blockTimestamp", blockTimestamp);


    }
}
