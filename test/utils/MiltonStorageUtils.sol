// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/amm/MiltonStorage.sol";

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
		address miltonStorageProxyAddress = miltonStorageProxy.deploy(address(miltonStorageFactory), deployer, abi.encodeWithSignature("initialize()", ""));
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

	function getMiltonStorageAddresses(
		address miltonStorageUsdt, 
		address miltonStorageUsdc,
		address miltonStorageDai
	) public pure returns (address[] memory) {
		address[] memory miltonStorageAddresses = new address[](3);
		miltonStorageAddresses[0] = miltonStorageUsdt;
		miltonStorageAddresses[1] = miltonStorageUsdc;
		miltonStorageAddresses[2] = miltonStorageDai;
		return miltonStorageAddresses;
	}

}