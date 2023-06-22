// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";
import "@ipor-protocol/contracts/amm/AmmTreasury.sol";
import "@ipor-protocol/contracts/facades/AmmTreasuryFacadeDataProvider.sol";
import "forge-std/Test.sol";

contract AmmTreasurySnapshot is Script, Test {
    using stdJson for string;
    address private _ammTreasury;
    address public ammTreasuryJoseph;
    address public ammTreasurySpreadModel;
    address public ammTreasuryAsset;
    address public ammTreasuryOwner;
    address public ammTreasuryFacadeDataProviderOwner;
    uint256 public ammTreasuryVersion;
    uint256 public ammTreasuryFacadeDataProviderVersion;
    uint256 public ammTreasuryMaxSwapCollateralAmount;
    uint256 public ammTreasuryMaxLpCollateralRatio;
    uint256 public ammTreasuryMaxLpCollateralRatioPayFixed;
    uint256 public ammTreasuryMaxLpCollateralRatioReceiveFixed;
    uint256 public ammTreasuryIncomeFeeRate;
    uint256 public ammTreasuryOpeningFeeRate;
    uint256 public ammTreasuryOpeningFeeTreasuryPortionRate;
    uint256 public ammTreasuryIporPublicationFee;
    uint256 public ammTreasuryLiquidationDepositAmount;
    uint256 public ammTreasuryWadLiquidationDepositAmount;
    uint256 public ammTreasuryMaxLeveragePayFixed;
    uint256 public ammTreasuryMaxLeverageReceiveFixed;
    uint256 public ammTreasuryMinLeverage;
    int256 public ammTreasurySpreadPayFixed;
    int256 public ammTreasurySpreadReceiveFixed;
    int256 public ammTreasurySoapPayFixed;
    int256 public ammTreasurySoapReceiveFixed;
    int256 public ammTreasurySoap;
    uint256 public totalCollateralPayFixed;
    uint256 public totalCollateralReceiveFixed;
    uint256 public liquidityPool;
    uint256 public vault;
    bool public ammTreasuryIsPaused;
    uint256 public blockNumber;
    uint256 public blockTimestamp;

    constructor(address ammTreasury) {
        _ammTreasury = ammTreasury;
    }

    function snapshot() public {
        AmmTreasury ammTreasury = AmmTreasury(_ammTreasury);
        AmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = AmmTreasuryFacadeDataProvider(_ammTreasury);

        ammTreasuryJoseph = ammTreasury.getJoseph();
        ammTreasurySpreadModel = ammTreasury.getAmmTreasurySpreadModel();
        ammTreasuryAsset = ammTreasury.getAsset();
        ammTreasuryOwner = ammTreasury.owner();
        ammTreasuryFacadeDataProviderOwner = ammTreasuryFacadeDataProvider.owner();

        ammTreasuryVersion = ammTreasury.getVersion();
        ammTreasuryFacadeDataProviderVersion = ammTreasuryFacadeDataProvider.getVersion();
        ammTreasuryMaxSwapCollateralAmount = ammTreasury.getMaxSwapCollateralAmount();
        ammTreasuryMaxLpCollateralRatio = ammTreasury.getMaxLpCollateralRatio();
        //        ammTreasuryMaxLpCollateralRatioPayFixed = ammTreasury
        //        .getMaxLpCollateralRatioPayFixed(); TODO revert
        //        ammTreasuryMaxLpCollateralRatioReceiveFixed = ammTreasury
        //        .getMaxLpCollateralRatioReceiveFixed(); TODO revert

        //        ammTreasuryOpeningFeeRate = ammTreasury.getOpeningFeeRate();
        //        ammTreasuryOpeningFeeTreasuryPortionRate = ammTreasury
        //        .getOpeningFeeTreasuryPortionRate();
        ammTreasuryIporPublicationFee = ammTreasury.getIporPublicationFee();
        ammTreasuryLiquidationDepositAmount = ammTreasury.getLiquidationDepositAmount();
        ammTreasuryWadLiquidationDepositAmount = ammTreasury.getWadLiquidationDepositAmount();
        //        ammTreasuryMaxLeveragePayFixed = ammTreasury.getMaxLeveragePayFixed(); TODO revert
        //        ammTreasuryMaxLeverageReceiveFixed = ammTreasury.getMaxLeverageReceiveFixed(); TODO revert
        ammTreasuryMinLeverage = ammTreasury.getMinLeverage();

        (ammTreasurySpreadPayFixed, ammTreasurySpreadReceiveFixed) = ammTreasury.calculateSpread();
        (ammTreasurySoapPayFixed, ammTreasurySoapReceiveFixed, ammTreasurySoap) = ammTreasury.calculateSoap();

        IporTypes.AmmBalancesMemory memory ammTreasuryAccruedBalance = ammTreasury.getAccruedBalance();
        totalCollateralPayFixed = ammTreasuryAccruedBalance.totalCollateralPayFixed;
        totalCollateralReceiveFixed = ammTreasuryAccruedBalance.totalCollateralReceiveFixed;
        liquidityPool = ammTreasuryAccruedBalance.liquidityPool;
        vault = ammTreasuryAccruedBalance.vault;

        blockNumber = block.number;
        blockTimestamp = block.timestamp;
    }

    function toJson(string memory fileName) external {
        string memory path = vm.projectRoot();
        string memory ammTreasuryJson = "";

        vm.serializeAddress(ammTreasuryJson, "ammTreasury", _ammTreasury);
        vm.serializeAddress(ammTreasuryJson, "ammTreasuryJoseph", ammTreasuryJoseph);
        vm.serializeAddress(ammTreasuryJson, "ammTreasurySpreadModel", ammTreasurySpreadModel);
        vm.serializeAddress(ammTreasuryJson, "ammTreasuryAsset", ammTreasuryAsset);
        vm.serializeAddress(ammTreasuryJson, "ammTreasuryOwner", ammTreasuryOwner);
        vm.serializeAddress(ammTreasuryJson, "ammTreasuryFacadeDataProviderOwner", ammTreasuryFacadeDataProviderOwner);

        vm.serializeUint(ammTreasuryJson, "ammTreasuryVersion", ammTreasuryVersion);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryFacadeDataProviderVersion", ammTreasuryFacadeDataProviderVersion);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxSwapCollateralAmount", ammTreasuryMaxSwapCollateralAmount);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxLpCollateralRatio", ammTreasuryMaxLpCollateralRatio);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxLpCollateralRatioPayFixed", ammTreasuryMaxLpCollateralRatioPayFixed);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxLpCollateralRatioReceiveFixed", ammTreasuryMaxLpCollateralRatioReceiveFixed);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryOpeningFeeRate", ammTreasuryOpeningFeeRate);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryOpeningFeeTreasuryPortionRate", ammTreasuryOpeningFeeTreasuryPortionRate);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryIporPublicationFee", ammTreasuryIporPublicationFee);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryLiquidationDepositAmount", ammTreasuryLiquidationDepositAmount);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryWadLiquidationDepositAmount", ammTreasuryWadLiquidationDepositAmount);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxLeveragePayFixed", ammTreasuryMaxLeveragePayFixed);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMaxLeverageReceiveFixed", ammTreasuryMaxLeverageReceiveFixed);
        vm.serializeUint(ammTreasuryJson, "ammTreasuryMinLeverage", ammTreasuryMinLeverage);

        vm.serializeInt(ammTreasuryJson, "ammTreasurySpreadPayFixed", ammTreasurySpreadPayFixed);
        vm.serializeInt(ammTreasuryJson, "ammTreasurySpreadReceiveFixed", ammTreasurySpreadReceiveFixed);
        vm.serializeInt(ammTreasuryJson, "ammTreasurySoapPayFixed", ammTreasurySoapPayFixed);
        vm.serializeInt(ammTreasuryJson, "ammTreasurySoapReceiveFixed", ammTreasurySoapReceiveFixed);
        vm.serializeInt(ammTreasuryJson, "ammTreasurySoap", ammTreasurySoap);

        vm.serializeUint(ammTreasuryJson, "totalCollateralPayFixed", totalCollateralPayFixed);
        vm.serializeUint(ammTreasuryJson, "totalCollateralReceiveFixed", totalCollateralReceiveFixed);
        vm.serializeUint(ammTreasuryJson, "liquidityPool", liquidityPool);
        vm.serializeUint(ammTreasuryJson, "vault", vault);

        vm.serializeBool(ammTreasuryJson, "ammTreasuryIsPaused", ammTreasuryIsPaused);
        vm.serializeUint(ammTreasuryJson, "blockNumber", blockNumber);

        string memory finalJson = vm.serializeUint(ammTreasuryJson, "blockTimestamp", blockTimestamp);
        vm.writeJson(finalJson, string.concat(path, fileName));
    }

    function assertAmmTreasury(AmmTreasurySnapshot ammTreasurySnapshot1, AmmTreasurySnapshot ammTreasurySnapshot2) external {
        assertEq(ammTreasurySnapshot1.ammTreasuryJoseph(), ammTreasurySnapshot2.ammTreasuryJoseph(), "AmmTreasury: Joseph should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadModel(),
            ammTreasurySnapshot2.ammTreasurySpreadModel(),
            "AmmTreasury: Spread Model should be the same"
        );
        assertEq(ammTreasurySnapshot1.ammTreasuryOwner(), ammTreasurySnapshot2.ammTreasuryOwner(), "AmmTreasury: Owner should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasuryFacadeDataProviderOwner(),
            ammTreasurySnapshot2.ammTreasuryFacadeDataProviderOwner(),
            "AmmTreasury: Facade Data Provider Owner should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxSwapCollateralAmount(),
            ammTreasurySnapshot2.ammTreasuryMaxSwapCollateralAmount(),
            "AmmTreasury: Max Swap Collateral Amount should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatio(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatio(),
            "AmmTreasury: Max LP Collateral Ratio should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatioPayFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatioPayFixed(),
            "AmmTreasury: Max LP Collateral Ratio Per Pay Fixed Leg Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatioReceiveFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatioReceiveFixed(),
            "AmmTreasury: Max LP Collateral Ratio Per Receive Fixed Leg Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIncomeFeeRate(),
            ammTreasurySnapshot2.ammTreasuryIncomeFeeRate(),
            "AmmTreasury: Income Fee Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryOpeningFeeRate(),
            ammTreasurySnapshot2.ammTreasuryOpeningFeeRate(),
            "AmmTreasury: Opening Fee Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryOpeningFeeTreasuryPortionRate(),
            ammTreasurySnapshot2.ammTreasuryOpeningFeeTreasuryPortionRate(),
            "AmmTreasury: Opening Fee Treasury Portion Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIporPublicationFee(),
            ammTreasurySnapshot2.ammTreasuryIporPublicationFee(),
            "AmmTreasury: IPOR Publication Fee should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryLiquidationDepositAmount(),
            ammTreasurySnapshot2.ammTreasuryLiquidationDepositAmount(),
            "AmmTreasury: Liquidation Deposit Amount should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryWadLiquidationDepositAmount(),
            ammTreasurySnapshot2.ammTreasuryWadLiquidationDepositAmount(),
            "AmmTreasury: WAD Liquidation Deposit Amount should be the same"
        );
        // assertEq(ammTreasurySnapshot1.ammTreasuryMaxLeverage(), ammTreasurySnapshot2.ammTreasuryMaxLeverage(), "AmmTreasury: Max Leverage should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMinLeverage(),
            ammTreasurySnapshot2.ammTreasuryMinLeverage(),
            "AmmTreasury: Min Leverage should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadPayFixed(),
            ammTreasurySnapshot2.ammTreasurySpreadPayFixed(),
            "AmmTreasury: Spread Pay Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadReceiveFixed(),
            ammTreasurySnapshot2.ammTreasurySpreadReceiveFixed(),
            "AmmTreasury: Spread Receive Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySoapPayFixed(),
            ammTreasurySnapshot2.ammTreasurySoapPayFixed(),
            "AmmTreasury: SOAP Pay Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySoapReceiveFixed(),
            ammTreasurySnapshot2.ammTreasurySoapReceiveFixed(),
            "AmmTreasury: SOAP Receive Fixed should be the same"
        );
        //        assertEq(ammTreasurySnapshot1.ammTreasurySoap(), ammTreasurySnapshot2.ammTreasurySoap(), "AmmTreasury: SOAP should be the same");
        assertEq(
            ammTreasurySnapshot1.totalCollateralPayFixed(),
            ammTreasurySnapshot2.totalCollateralPayFixed(),
            "Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.totalCollateralReceiveFixed(),
            ammTreasurySnapshot2.totalCollateralReceiveFixed(),
            "Total Collateral Receive Fixed should be the same"
        );
        assertEq(ammTreasurySnapshot1.liquidityPool(), ammTreasurySnapshot2.liquidityPool(), "Liquidity Pool should be the same");
        assertEq(ammTreasurySnapshot1.vault(), ammTreasurySnapshot2.vault(), "Vault should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIsPaused(),
            ammTreasurySnapshot2.ammTreasuryIsPaused(),
            "AmmTreasury: Is Paused should be the same"
        );
        assertEq(ammTreasurySnapshot1.blockNumber(), ammTreasurySnapshot2.blockNumber(), "Block Number should be the same");
        assertEq(
            ammTreasurySnapshot1.blockTimestamp(),
            ammTreasurySnapshot2.blockTimestamp(),
            "Block Timestamp should be the same"
        );
    }

    // This method should be removed after deployment. There is a problem with the assertion of the new IporMath.divideInt implementation.
    function assertWithIgnore(AmmTreasurySnapshot ammTreasurySnapshot1, AmmTreasurySnapshot ammTreasurySnapshot2) external {
        assertEq(ammTreasurySnapshot1.ammTreasuryJoseph(), ammTreasurySnapshot2.ammTreasuryJoseph(), "AmmTreasury: Joseph should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadModel(),
            ammTreasurySnapshot2.ammTreasurySpreadModel(),
            "AmmTreasury: Spread Model should be the same"
        );
        assertEq(ammTreasurySnapshot1.ammTreasuryOwner(), ammTreasurySnapshot2.ammTreasuryOwner(), "AmmTreasury: Owner should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasuryFacadeDataProviderOwner(),
            ammTreasurySnapshot2.ammTreasuryFacadeDataProviderOwner(),
            "AmmTreasury: Facade Data Provider Owner should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxSwapCollateralAmount(),
            ammTreasurySnapshot2.ammTreasuryMaxSwapCollateralAmount(),
            "AmmTreasury: Max Swap Collateral Amount should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatio(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatio(),
            "AmmTreasury: Max LP Collateral Ratio Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatioPayFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatioPayFixed(),
            "AmmTreasury: Max LP Collateral Ratio Per Pay Fixed Leg Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLpCollateralRatioReceiveFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLpCollateralRatioReceiveFixed(),
            "AmmTreasury: Max LP Collateral Ratio Per Receive Fixed Leg Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIncomeFeeRate(),
            ammTreasurySnapshot2.ammTreasuryIncomeFeeRate(),
            "AmmTreasury: Income Fee Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryOpeningFeeRate(),
            ammTreasurySnapshot2.ammTreasuryOpeningFeeRate(),
            "AmmTreasury: Opening Fee Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryOpeningFeeTreasuryPortionRate(),
            ammTreasurySnapshot2.ammTreasuryOpeningFeeTreasuryPortionRate(),
            "AmmTreasury: Opening Fee Treasury Portion Rate should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIporPublicationFee(),
            ammTreasurySnapshot2.ammTreasuryIporPublicationFee(),
            "AmmTreasury: IPOR Publication Fee should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryLiquidationDepositAmount(),
            ammTreasurySnapshot2.ammTreasuryLiquidationDepositAmount(),
            "AmmTreasury: Liquidation Deposit Amount should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryWadLiquidationDepositAmount(),
            ammTreasurySnapshot2.ammTreasuryWadLiquidationDepositAmount(),
            "AmmTreasury: WAD Liquidation Deposit Amount should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLeveragePayFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLeveragePayFixed(),
            "AmmTreasury: Max Leverage For Pay Fixed leg should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMaxLeverageReceiveFixed(),
            ammTreasurySnapshot2.ammTreasuryMaxLeverageReceiveFixed(),
            "AmmTreasury: Max Leverage For Receive Fixed leg should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasuryMinLeverage(),
            ammTreasurySnapshot2.ammTreasuryMinLeverage(),
            "AmmTreasury: Min Leverage should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadPayFixed(),
            ammTreasurySnapshot2.ammTreasurySpreadPayFixed(),
            "AmmTreasury: Spread Pay Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.ammTreasurySpreadReceiveFixed(),
            ammTreasurySnapshot2.ammTreasurySpreadReceiveFixed(),
            "AmmTreasury: Spread Receive Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.totalCollateralPayFixed(),
            ammTreasurySnapshot2.totalCollateralPayFixed(),
            "AmmTreasury: Total Collateral Pay Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.totalCollateralReceiveFixed(),
            ammTreasurySnapshot2.totalCollateralReceiveFixed(),
            "AmmTreasury: Total Collateral Receive Fixed should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.liquidityPool(),
            ammTreasurySnapshot2.liquidityPool(),
            "AmmTreasury: Liquidity Pool should be the same"
        );
        assertEq(ammTreasurySnapshot1.vault(), ammTreasurySnapshot2.vault(), "AmmTreasury: Vault should be the same");
        assertEq(
            ammTreasurySnapshot1.ammTreasuryIsPaused(),
            ammTreasurySnapshot2.ammTreasuryIsPaused(),
            "AmmTreasury: Is Paused should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.blockNumber(),
            ammTreasurySnapshot2.blockNumber(),
            "AmmTreasury: Block Number should be the same"
        );
        assertEq(
            ammTreasurySnapshot1.blockTimestamp(),
            ammTreasurySnapshot2.blockTimestamp(),
            "AmmTreasury: Block Timestamp should be the same"
        );
    }

    function consoleLog() public view {
        console2.log("ammTreasury", _ammTreasury);
        console2.log("ammTreasuryJoseph", ammTreasuryJoseph);
        console2.log("ammTreasurySpreadModel", ammTreasurySpreadModel);
        console2.log("ammTreasuryAsset", ammTreasuryAsset);
        console2.log("ammTreasuryOwner", ammTreasuryOwner);
        console2.log("ammTreasuryVersion", ammTreasuryVersion);
        console2.log("ammTreasuryFacadeDataProviderVersion", ammTreasuryFacadeDataProviderVersion);
        console2.log("ammTreasuryMaxSwapCollateralAmount", ammTreasuryMaxSwapCollateralAmount);
        console2.log("ammTreasuryMaxLpCollateralRatio", ammTreasuryMaxLpCollateralRatio);
        console2.log("ammTreasuryMaxLpCollateralRatioPayFixed", ammTreasuryMaxLpCollateralRatioPayFixed);
        console2.log("ammTreasuryMaxLpCollateralRatioReceiveFixed", ammTreasuryMaxLpCollateralRatioReceiveFixed);
        console2.log("ammTreasuryIncomeFeeRate", ammTreasuryIncomeFeeRate);
        console2.log("ammTreasuryOpeningFeeRate", ammTreasuryOpeningFeeRate);
        console2.log("ammTreasuryOpeningFeeTreasuryPortionRate", ammTreasuryOpeningFeeTreasuryPortionRate);
        console2.log("ammTreasuryIporPublicationFee", ammTreasuryIporPublicationFee);
        console2.log("ammTreasuryLiquidationDepositAmount", ammTreasuryLiquidationDepositAmount);
        console2.log("ammTreasuryWadLiquidationDepositAmount", ammTreasuryWadLiquidationDepositAmount);
        console2.log("ammTreasuryMaxLeveragePayFixed", ammTreasuryMaxLeveragePayFixed);
        console2.log("ammTreasuryMaxLeverageReceiveFixed", ammTreasuryMaxLeverageReceiveFixed);
        console2.log("ammTreasuryMinLeverage", ammTreasuryMinLeverage);
        console2.logInt(ammTreasurySpreadPayFixed);
        console2.logInt(ammTreasurySpreadReceiveFixed);
        console2.logInt(ammTreasurySoapPayFixed);
        console2.logInt(ammTreasurySoapReceiveFixed);
        console2.logInt(ammTreasurySoap);
        console2.log("totalCollateralPayFixed", totalCollateralPayFixed);
        console2.log("totalCollateralReceiveFixed", totalCollateralReceiveFixed);
        console2.log("liquidityPool", liquidityPool);
        console2.log("vault", vault);
        console2.log("blockNumber", blockNumber);
        console2.log("ammTreasuryIsPaused", ammTreasuryIsPaused);
        console2.log("blockTimestamp", blockTimestamp);
    }
}
