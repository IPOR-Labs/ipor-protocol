// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/amm/MiltonStorage.sol";

contract MiltonStorageUtils is Test {
	
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

}