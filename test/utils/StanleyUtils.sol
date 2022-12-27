// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/stanley/MockCase2Stanley.sol";

contract StanleyUtils {

	/// ---------------------- Mock Cases Stanley ----------------------
	function getMockCase0Stanley(address asset) public returns (MockCase0Stanley){
		MockCase0Stanley mockStanley = new MockCase0Stanley(asset);
		return mockStanley;
	}

	function getMockCase1Stanley(address asset) public returns (MockCase1Stanley){
		MockCase1Stanley mockStanley = new MockCase1Stanley(asset);
		return mockStanley;
	}
	
	function getMockCase2Stanley(address asset) public returns (MockCase2Stanley){
		MockCase2Stanley mockStanley = new MockCase2Stanley(asset);
		return mockStanley;
	}
	/// ---------------------- Mock Cases Stanley ----------------------
}