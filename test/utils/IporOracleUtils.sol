// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/itf/ItfIporOracle.sol";

contract IporOracleUtils is Test {
	function prepareIporOracle(
		address[] memory accounts,
		address[] memory assets,
		uint32[] memory lastUpdateTimestamps,
		uint64[] memory exponentialMovingAverages,
		uint64[] memory exponentialWeightedMovingVariances	
	) public returns (ItfIporOracle) {
		ProxyTester iporOracleProxy = new ProxyTester();
		iporOracleProxy.setType("uups");
		ItfIporOracle iporOracleFactory = new ItfIporOracle();	
		address iporOracleProxyAddress = iporOracleProxy.deploy(address(iporOracleFactory), accounts[0], abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, lastUpdateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
		ItfIporOracle iporOracle = ItfIporOracle(iporOracleProxyAddress);
		if (accounts[1] != address(0)) {
			vm.prank(address(iporOracleProxy));
			iporOracle.addUpdater(accounts[1]);
		}
		return iporOracle;
	}

	function getIporOracle(address deployer, address updater, address asset) public returns (ItfIporOracle) {
		address[] memory accounts = new address[](2);
		accounts[0] = deployer;
		accounts[1] = updater;
		address[] memory assets = new address[](1);
		assets[0] = asset;
		uint32[] memory updateTimestamps = new uint32[](1);
		updateTimestamps[0] = uint32(block.timestamp);
		uint64[] memory exponentialMovingAverages = new uint64[](1);
		exponentialMovingAverages[0] = 0;
		uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);
		exponentialWeightedMovingVariances[0] = 0;
		ItfIporOracle iporOracle = prepareIporOracle(accounts, assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances);
		return iporOracle;
	}
}