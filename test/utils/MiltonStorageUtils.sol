// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonStorageUtils is Test {
    /// ------------------- MILTONSTORAGE -------------------
    struct MiltonStorages {
        ProxyTester miltonStorageUsdtProxy;
        MiltonStorage miltonStorageUsdt;
        ProxyTester miltonStorageUsdcProxy;
        MiltonStorage miltonStorageUsdc;
        ProxyTester miltonStorageDaiProxy;
        MiltonStorage miltonStorageDai;
    }
    /// ------------------- MILTONSTORAGE -------------------

    function prepareMiltonStorage(
        MiltonStorage miltonStorage,
        ProxyTester miltonStorageProxy,
        address joseph,
        address milton
    ) public returns (MiltonStorage) {
        vm.prank(address(miltonStorageProxy));
        miltonStorage.setJoseph(joseph);
        vm.prank(address(miltonStorageProxy));
        miltonStorage.setMilton(milton);
        return miltonStorage;
    }

    function getMiltonStorage(address deployer) public returns (ProxyTester, MiltonStorage) {
        ProxyTester miltonStorageProxy = new ProxyTester();
        miltonStorageProxy.setType("uups");
        MiltonStorage miltonStorageFactory = new MiltonStorage();
        address miltonStorageProxyAddress = miltonStorageProxy.deploy(
            address(miltonStorageFactory), deployer, abi.encodeWithSignature("initialize()", "")
        );
        MiltonStorage miltonStorage = MiltonStorage(miltonStorageProxyAddress);
        return (miltonStorageProxy, miltonStorage);
    }

    function getMiltonStorages(address deployer) public returns (MiltonStorages memory) {
        MiltonStorages memory miltonStorages;
        (miltonStorages.miltonStorageUsdtProxy, miltonStorages.miltonStorageUsdt) = getMiltonStorage(deployer);
        (miltonStorages.miltonStorageUsdcProxy, miltonStorages.miltonStorageUsdc) = getMiltonStorage(deployer);
        (miltonStorages.miltonStorageDaiProxy, miltonStorages.miltonStorageDai) = getMiltonStorage(deployer);
        return miltonStorages;
    }

    function getMiltonStorageAddresses(address miltonStorageUsdt, address miltonStorageUsdc, address miltonStorageDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory miltonStorageAddresses = new address[](3);
        miltonStorageAddresses[0] = miltonStorageUsdt;
        miltonStorageAddresses[1] = miltonStorageUsdc;
        miltonStorageAddresses[2] = miltonStorageDai;
        return miltonStorageAddresses;
    }

    function prepareSwapPayFixedStruct18DecSimpleCase1(address buyer) public view returns (AmmTypes.NewSwap memory) {
        AmmTypes.NewSwap memory newSwap;
        newSwap.buyer = buyer;
        newSwap.openTimestamp = block.timestamp;
        newSwap.collateral = TestConstants.USD_1_000_18DEC;
        newSwap.notional = TestConstants.USD_5_000_18DEC;
        newSwap.ibtQuantity = 123;
        newSwap.fixedInterestRate = 234;
        newSwap.liquidationDepositAmount = 20;
        newSwap.openingFeeLPAmount = TestConstants.USD_1_500_18DEC;
        newSwap.openingFeeTreasuryAmount = TestConstants.USD_1_500_18DEC;
        return newSwap;
    }
}
