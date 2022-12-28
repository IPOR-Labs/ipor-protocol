// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdt.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdc.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase3MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase4MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase5MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase6MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase3MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase4MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase5MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase6MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase1MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase6MiltonDai.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";

contract MiltonUtils is Test {

 /// ------------------- MILTON -------------------
	struct ItfMiltons {
		ProxyTester itfMiltonUsdtProxy;
		ItfMiltonUsdt itfMiltonUsdt;
		ProxyTester itfMiltonUsdcProxy;
		ItfMiltonUsdc itfMiltonUsdc;
		ProxyTester itfMiltonDaiProxy;
		ItfMiltonDai itfMiltonDai;
	}

	struct MockCase0Miltons {
		ProxyTester mockCase0MiltonUsdtProxy;
		MockCase0MiltonUsdt mockCase0MiltonUsdt;
		ProxyTester mockCase0MiltonUsdcProxy;
		MockCase0MiltonUsdc mockCase0MiltonUsdc;
		ProxyTester mockCase0MiltonDaiProxy;
		MockCase0MiltonDai mockCase0MiltonDai;
	}
 /// ------------------- MILTON -------------------

 /// ------------------- SPREAD MODEL -------------------
	function prepareMockSpreadModel(
		uint256 calculateQuotePayFixedValue,
		uint256 calculateQuoteReceiveFixedValue,
		int256 calculateSpreadPayFixedValue,
		int256 calculateSpreadReceiveFixedVaule
	) public returns (MockSpreadModel) {
		MockSpreadModel miltonSpreadModel = new MockSpreadModel(
			calculateQuotePayFixedValue,
			calculateQuoteReceiveFixedValue,
			calculateSpreadPayFixedValue,
			calculateSpreadReceiveFixedVaule
		);	
		return miltonSpreadModel;
	}
 /// ------------------- SPREAD MODEL -------------------
 /// ------------------- MILTON FACADE DATA PROVIDER -------------------
	function getMiltonFacadeDataProvider(
		address deployer,
		address iporOracle,
		address[] memory assets,
		address[] memory miltons,
		address[] memory miltonStorages,
		address[] memory josephs
	) public returns (ProxyTester, MiltonFacadeDataProvider){
		ProxyTester miltonFacadeDataProviderProxy = new ProxyTester();
		miltonFacadeDataProviderProxy.setType("uups");
		MiltonFacadeDataProvider miltonFacadeDataProviderFactory = new MiltonFacadeDataProvider();
		address miltonFacadeDataProviderProxyAddress = miltonFacadeDataProviderProxy.deploy(address(miltonFacadeDataProviderFactory), deployer, abi.encodeWithSignature("initialize(address,address[],address[],address[],address[])",iporOracle, assets, miltons, miltonStorages, josephs));
		MiltonFacadeDataProvider miltonFacadeDataProvider = MiltonFacadeDataProvider(miltonFacadeDataProviderProxyAddress);
		return (miltonFacadeDataProviderProxy, miltonFacadeDataProvider);
	}
 /// ------------------- MILTON FACADE DATA PROVIDER -------------------

 /// ------------------- ITFMILTON -------------------
	function getItfMiltonUsdt(
		address deployer,
		address tokenUsdt,
		address iporOracle,
		address miltonStorageUsdt,
		address miltonSpreadModel,
		address stanleyUsdt
	) public returns (ProxyTester, ItfMiltonUsdt){
		ProxyTester miltonUsdtProxy = new ProxyTester();
		miltonUsdtProxy.setType("uups");
		ItfMiltonUsdt itfMiltonUsdtFactory = new ItfMiltonUsdt();
		address miltonUsdtProxyAddress = miltonUsdtProxy.deploy(address(itfMiltonUsdtFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
		ItfMiltonUsdt itfMiltonUsdt = ItfMiltonUsdt(miltonUsdtProxyAddress);
		return (miltonUsdtProxy, itfMiltonUsdt);
	}

	function prepareItfMiltonUsdt(
		ItfMiltonUsdt miltonUsdt,
		address miltonUsdtProxy,
		address josephUsdt,
		address stanleyUsdt
	) public {
		vm.prank(miltonUsdtProxy);	
		miltonUsdt.setJoseph(josephUsdt);
		vm.prank(miltonUsdtProxy);
		miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
		vm.prank(miltonUsdtProxy);
		miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
	}

	function getItfMiltonUsdc(
		address deployer,
		address tokenUsdc,
		address iporOracle,
		address miltonStorageUsdc,
		address miltonSpreadModel,
		address stanleyUsdc
	) public returns (ProxyTester, ItfMiltonUsdc){
		ProxyTester miltonUsdcProxy = new ProxyTester();
		miltonUsdcProxy.setType("uups");
		ItfMiltonUsdc itfMiltonUsdcFactory = new ItfMiltonUsdc();
		address miltonUsdcProxyAddress = miltonUsdcProxy.deploy(address(itfMiltonUsdcFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
		ItfMiltonUsdc itfMiltonUsdc = ItfMiltonUsdc(miltonUsdcProxyAddress);
		return (miltonUsdcProxy, itfMiltonUsdc);
	}

	function prepareItfMiltonUsdc(
		ItfMiltonUsdc miltonUsdc,
		address miltonUsdcProxy,
		address josephUsdc,
		address stanleyUsdc
	) public {
		vm.prank(miltonUsdcProxy);	
		miltonUsdc.setJoseph(josephUsdc);
		vm.prank(miltonUsdcProxy);
		miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
		vm.prank(miltonUsdcProxy);
		miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
	}

	function getItfMiltonDai(
		address deployer,
		address tokenDai,
		address iporOracle,
		address miltonStorageDai,
		address miltonSpreadModel,
		address stanleyDai
	) public returns (ProxyTester, ItfMiltonDai){
		ProxyTester miltonDaiProxy = new ProxyTester();
		miltonDaiProxy.setType("uups");
		ItfMiltonDai itfMiltonDaiFactory = new ItfMiltonDai();
		address miltonDaiProxyAddress = miltonDaiProxy.deploy(address(itfMiltonDaiFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
		ItfMiltonDai itfMiltonDai = ItfMiltonDai(miltonDaiProxyAddress);
		return (miltonDaiProxy, itfMiltonDai);
	}

	function prepareItfMiltonDai(
		ItfMiltonDai miltonDai,
		address miltonDaiProxy,
		address josephDai,
		address stanleyDai
	) public {
		vm.prank(miltonDaiProxy);	
		miltonDai.setJoseph(josephDai);
		vm.prank(miltonDaiProxy);
		miltonDai.setupMaxAllowanceForAsset(josephDai);
		vm.prank(miltonDaiProxy);
		miltonDai.setupMaxAllowanceForAsset(stanleyDai);
	}

	function getItfMiltons (
		address deployer,
		address iporOracle, 
		address miltonSpreadModel,
		address tokenUsdt,
		address tokenUsdc,
		address tokenDai,
		address[] memory miltonStorageAddresses, 
		address[] memory stanleyAddresses
	) public returns (ItfMiltons memory) {
		ItfMiltons memory mockCase0Miltons;
		(mockCase0Miltons.itfMiltonUsdtProxy, mockCase0Miltons.itfMiltonUsdt) = getItfMiltonUsdt(deployer, tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]);
		(mockCase0Miltons.itfMiltonUsdcProxy, mockCase0Miltons.itfMiltonUsdc) = getItfMiltonUsdc(deployer, tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]);
		(mockCase0Miltons.itfMiltonDaiProxy, mockCase0Miltons.itfMiltonDai) = getItfMiltonDai(deployer, tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]);
		return mockCase0Miltons;
	}

	function getItfMiltonAddresses(
		address miltonUsdt,
		address miltonUsdc,
		address miltonDai
	) public pure returns(address[] memory) {
		address[] memory miltons = new address[](3);
		miltons[0] = miltonUsdt;
		miltons[1] = miltonUsdc;
		miltons[2] = miltonDai;
		return miltons;
	}

 /// ------------------- ITFMILTON -------------------

 /// ------------------- Mock Cases Milton -------------------

	function getMockCase0MiltonUsdt(
		address deployer,
		address tokenUsdt,
		address iporOracle,
		address miltonStorageUsdt,
		address miltonSpreadModel,
		address stanleyUsdt
	) public returns (ProxyTester, MockCase0MiltonUsdt){
		ProxyTester miltonUsdtProxy = new ProxyTester();
		miltonUsdtProxy.setType("uups");
		MockCase0MiltonUsdt mockCase0MiltonUsdtFactory = new MockCase0MiltonUsdt();
		address miltonUsdtProxyAddress = miltonUsdtProxy.deploy(address(mockCase0MiltonUsdtFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
		MockCase0MiltonUsdt mockCase0MiltonUsdt = MockCase0MiltonUsdt(miltonUsdtProxyAddress);
		return (miltonUsdtProxy, mockCase0MiltonUsdt);
	}

	function prepareMockCase0MiltonUsdt(
		MockCase0MiltonUsdt miltonUsdt,
		address miltonUsdtProxy,
		address josephUsdt,
		address stanleyUsdt
	) public {
		vm.prank(miltonUsdtProxy);	
		miltonUsdt.setJoseph(josephUsdt);
		vm.prank(miltonUsdtProxy);
		miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
		vm.prank(miltonUsdtProxy);
		miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
	}
	
	function getMockCase0MiltonUsdc(
		address deployer,
		address tokenUsdc,
		address iporOracle,
		address miltonStorageUsdc,
		address miltonSpreadModel,
		address stanleyUsdc
	) public returns (ProxyTester, MockCase0MiltonUsdc){
		ProxyTester miltonUsdcProxy = new ProxyTester();
		miltonUsdcProxy.setType("uups");
		MockCase0MiltonUsdc mockCase0MiltonUsdcFactory = new MockCase0MiltonUsdc();
		address miltonUsdcProxyAddress = miltonUsdcProxy.deploy(address(mockCase0MiltonUsdcFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
		MockCase0MiltonUsdc mockCase0MiltonUsdc = MockCase0MiltonUsdc(miltonUsdcProxyAddress);
		return (miltonUsdcProxy, mockCase0MiltonUsdc);
	}

	function prepareMockCase0MiltonUsdc(
		MockCase0MiltonUsdc miltonUsdc,
		address miltonUsdcProxy,
		address josephUsdc,
		address stanleyUsdc
	) public {
		vm.prank(miltonUsdcProxy);	
		miltonUsdc.setJoseph(josephUsdc);
		vm.prank(miltonUsdcProxy);
		miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
		vm.prank(miltonUsdcProxy);
		miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
	}

	function getMockCase0MiltonDai(
		address deployer,
		address tokenDai,
		address iporOracle,
		address miltonStorageDai,
		address miltonSpreadModel,
		address stanleyDai
	) public returns (ProxyTester, MockCase0MiltonDai){
		ProxyTester miltonDaiProxy = new ProxyTester();
		miltonDaiProxy.setType("uups");
		MockCase0MiltonDai mockCase0MiltonDaiFactory = new MockCase0MiltonDai();
		address miltonDaiProxyAddress = miltonDaiProxy.deploy(address(mockCase0MiltonDaiFactory), deployer, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
		MockCase0MiltonDai mockCase0MiltonDai = MockCase0MiltonDai(miltonDaiProxyAddress);
		return (miltonDaiProxy, mockCase0MiltonDai);
	}

	function prepareMockCase0MiltonDai(
		MockCase0MiltonDai miltonDai,
		address miltonDaiProxy,
		address josephDai,
		address stanleyDai
	) public {
		vm.prank(miltonDaiProxy);	
		miltonDai.setJoseph(josephDai);
		vm.prank(miltonDaiProxy);
		miltonDai.setupMaxAllowanceForAsset(josephDai);
		vm.prank(miltonDaiProxy);
		miltonDai.setupMaxAllowanceForAsset(stanleyDai);
	}

	function getMockCase0Miltons (
		address deployer,
		address iporOracle, 
		address miltonSpreadModel,
		address tokenUsdt,
		address tokenUsdc,
		address tokenDai,
		address[] memory miltonStorageAddresses, 
		address[] memory stanleyAddresses
	) public returns (MockCase0Miltons memory) {
		MockCase0Miltons memory mockCase0Miltons;
		(mockCase0Miltons.mockCase0MiltonUsdtProxy, mockCase0Miltons.mockCase0MiltonUsdt) = getMockCase0MiltonUsdt(deployer, tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]);
		(mockCase0Miltons.mockCase0MiltonUsdcProxy, mockCase0Miltons.mockCase0MiltonUsdc) = getMockCase0MiltonUsdc(deployer, tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]);
		(mockCase0Miltons.mockCase0MiltonDaiProxy, mockCase0Miltons.mockCase0MiltonDai) = getMockCase0MiltonDai(deployer, tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]);
		return mockCase0Miltons;
	}

	function getMockCase0MiltonAddresses(
		address miltonUsdt,
		address miltonUsdc,
		address miltonDai
	) public pure returns(address[] memory) {
		address[] memory miltons = new address[](3);
		miltons[0] = miltonUsdt;
		miltons[1] = miltonUsdc;
		miltons[2] = miltonDai;
		return miltons;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase1MiltonUsdt() public returns (MockCase1MiltonUsdt){
		MockCase1MiltonUsdt mockCase1MiltonUsdt = new MockCase1MiltonUsdt();
		return mockCase1MiltonUsdt;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase2MiltonUsdt() public returns (MockCase2MiltonUsdt){
		MockCase2MiltonUsdt mockCase2MiltonUsdt = new MockCase2MiltonUsdt();
		return mockCase2MiltonUsdt;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase3MiltonUsdt() public returns (MockCase3MiltonUsdt){
		MockCase3MiltonUsdt mockCase3MiltonUsdt = new MockCase3MiltonUsdt();
		return mockCase3MiltonUsdt;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase4MiltonUsdt() public returns (MockCase4MiltonUsdt){
		MockCase4MiltonUsdt mockCase4MiltonUsdt = new MockCase4MiltonUsdt();
		return mockCase4MiltonUsdt;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase5MiltonUsdt() public returns (MockCase5MiltonUsdt){
		MockCase5MiltonUsdt mockCase5MiltonUsdt = new MockCase5MiltonUsdt();
		return mockCase5MiltonUsdt;
	}

	function getMockCase6MiltonUsdt() public returns (MockCase6MiltonUsdt){
		MockCase6MiltonUsdt mockCase6MiltonUsdt = new MockCase6MiltonUsdt();
		return mockCase6MiltonUsdt;
	}

	function getMockCase0MiltonUsdc() public returns (MockCase0MiltonUsdc){
		MockCase0MiltonUsdc mockCase0MiltonUsdc = new MockCase0MiltonUsdc();
		return mockCase0MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase1MiltonUsdc() public returns (MockCase1MiltonUsdc){
		MockCase1MiltonUsdc mockCase1MiltonUsdc = new MockCase1MiltonUsdc();
		return mockCase1MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase2MiltonUsdc() public returns (MockCase2MiltonUsdc){
		MockCase2MiltonUsdc mockCase2MiltonUsdc = new MockCase2MiltonUsdc();
		return mockCase2MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase3MiltonUsdc() public returns (MockCase3MiltonUsdc){
		MockCase3MiltonUsdc mockCase3MiltonUsdc = new MockCase3MiltonUsdc();
		return mockCase3MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase4MiltonUsdc() public returns (MockCase4MiltonUsdc){
		MockCase4MiltonUsdc mockCase4MiltonUsdc = new MockCase4MiltonUsdc();
		return mockCase4MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase5MiltonUsdc() public returns (MockCase5MiltonUsdc){
		MockCase5MiltonUsdc mockCase5MiltonUsdc = new MockCase5MiltonUsdc();
		return mockCase5MiltonUsdc;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase6MiltonUsdc() public returns (MockCase6MiltonUsdc){
		MockCase6MiltonUsdc mockCase6MiltonUsdc = new MockCase6MiltonUsdc();
		return mockCase6MiltonUsdc;
	}
	
	/// ------------------------------------------------------------------------------------

	function getMockCase0MiltonDai() public returns (MockCase0MiltonDai){
		MockCase0MiltonDai mockCase0MiltonDai = new MockCase0MiltonDai();
		return mockCase0MiltonDai;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase1MiltonDai() public returns (MockCase1MiltonDai){
		MockCase1MiltonDai mockCase1MiltonDai = new MockCase1MiltonDai();
		return mockCase1MiltonDai;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase2MiltonDai() public returns (MockCase2MiltonDai){
		MockCase2MiltonDai mockCase2MiltonDai = new MockCase2MiltonDai();
		return mockCase2MiltonDai;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase3MiltonDai() public returns (MockCase3MiltonDai){
		MockCase3MiltonDai mockCase3MiltonDai = new MockCase3MiltonDai();
		return mockCase3MiltonDai;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase4MiltonDai() public returns (MockCase4MiltonDai){
		MockCase4MiltonDai mockCase4MiltonDai = new MockCase4MiltonDai();
		return mockCase4MiltonDai;
	}

	/// ------------------------------------------------------------------------------------

	function getMockCase5MiltonDai() public returns (MockCase5MiltonDai){
		MockCase5MiltonDai mockCase5MiltonDai = new MockCase5MiltonDai();
		return mockCase5MiltonDai;
	}

	function getMockCase6MiltonDai() public returns (MockCase6MiltonDai){
		MockCase6MiltonDai mockCase6MiltonDai = new MockCase6MiltonDai();
		return mockCase6MiltonDai;
	}
/// ------------------- Mock Cases Milton -------------------

/// ------------------- Mock Cases Milton Spread -------------------
	function prepareMiltonSpreadBaseUsdt() public returns (MockBaseMiltonSpreadModelUsdt){
		MockBaseMiltonSpreadModelUsdt mockBaseMiltonSpreadModelUsdt = new MockBaseMiltonSpreadModelUsdt();
		return mockBaseMiltonSpreadModelUsdt;
	}

	function prepareMiltonSpreadBaseUsdc() public returns (MockBaseMiltonSpreadModelUsdc) {
		MockBaseMiltonSpreadModelUsdc mockBaseMiltonSpreadModelUsdc = new MockBaseMiltonSpreadModelUsdc();
		return mockBaseMiltonSpreadModelUsdc;
	}

	function prepareMiltonSpreadBaseDai () public returns (MockBaseMiltonSpreadModelDai){
		MockBaseMiltonSpreadModelDai mockBaseMiltonSpreadModelDai = new MockBaseMiltonSpreadModelDai();
		return mockBaseMiltonSpreadModelDai;
	}
/// ------------------- Mock Cases Milton Spread -------------------
}