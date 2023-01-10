// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/interfaces/IMiltonFacadeDataProvider.sol";
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
        ItfMiltonUsdt itfMiltonUsdt;
        ItfMiltonUsdc itfMiltonUsdc;
        ItfMiltonDai itfMiltonDai;
    }

    struct MockCase0Miltons {
        MockCase0MiltonUsdt mockCase0MiltonUsdt;
        MockCase0MiltonUsdc mockCase0MiltonUsdc;
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
        address iporOracle,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs
    ) public returns (IMiltonFacadeDataProvider) {
        MiltonFacadeDataProvider miltonFacadeDataProviderImplementation = new MiltonFacadeDataProvider();
        ERC1967Proxy miltonFacadeDataProviderProxy =
        new ERC1967Proxy(address(miltonFacadeDataProviderImplementation), abi.encodeWithSignature( "initialize(address,address[],address[],address[],address[])", iporOracle, assets, miltons, miltonStorages, josephs));
        IMiltonFacadeDataProvider miltonFacadeDataProvider =
            IMiltonFacadeDataProvider(address(miltonFacadeDataProviderProxy));
        return miltonFacadeDataProvider;
    }

    /// ------------------- MILTON FACADE DATA PROVIDER -------------------

    /// ------------------- ITFMILTON -------------------
    function getItfMiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ItfMiltonUsdt) {
        ItfMiltonUsdt itfMiltonUsdtImplementation = new ItfMiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(itfMiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        ItfMiltonUsdt miltonUsdt = ItfMiltonUsdt(address(miltonUsdtProxy));
        return miltonUsdt;
    }

    function prepareItfMiltonUsdt(ItfMiltonUsdt miltonUsdt, address josephUsdt, address stanleyUsdt) public {
        miltonUsdt.setJoseph(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getItfMiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ItfMiltonUsdc) {
        ItfMiltonUsdc itfMiltonUsdcImplementation = new ItfMiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(itfMiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        ItfMiltonUsdc miltonUsdc = ItfMiltonUsdc(address(miltonUsdcProxy));
        return miltonUsdc;
    }

    function prepareItfMiltonUsdc(ItfMiltonUsdc miltonUsdc, address josephUsdc, address stanleyUsdc) public {
        miltonUsdc.setJoseph(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getItfMiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ItfMiltonDai) {
        ItfMiltonDai itfMiltonDaiImplementation = new ItfMiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(itfMiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        ItfMiltonDai miltonDai = ItfMiltonDai(address(miltonDaiProxy));
        return miltonDai;
    }

    function prepareItfMiltonDai(ItfMiltonDai miltonDai, address josephDai, address stanleyDai) public {
        miltonDai.setJoseph(josephDai);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    function getItfMiltons(
        address iporOracle,
        address miltonSpreadModel,
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (ItfMiltons memory) {
        ItfMiltons memory mockCase0Miltons;
        mockCase0Miltons.itfMiltonUsdt =
            getItfMiltonUsdt(tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]);
        mockCase0Miltons.itfMiltonUsdc =
            getItfMiltonUsdc(tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]);
        mockCase0Miltons.itfMiltonDai =
            getItfMiltonDai(tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]);
        return mockCase0Miltons;
    }

    function getItfMiltonAddresses(address miltonUsdt, address miltonUsdc, address miltonDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory miltons = new address[](3);
        miltons[0] = miltonUsdt;
        miltons[1] = miltonUsdc;
        miltons[2] = miltonDai;
        return miltons;
    }

    /// ------------------- ITFMILTON -------------------

    /// ------------------- Mock Cases Milton -------------------

    function getMockCase0MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase0MiltonUsdt) {
        MockCase0MiltonUsdt mockCase0MiltonUsdtImplementation = new MockCase0MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase0MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        MockCase0MiltonUsdt miltonUsdt = MockCase0MiltonUsdt(address(miltonUsdtProxy));
        return miltonUsdt;
    }

    function prepareMockCase0MiltonUsdt(MockCase0MiltonUsdt miltonUsdt, address josephUsdt, address stanleyUsdt)
        public
    {
        miltonUsdt.setJoseph(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase0MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase0MiltonUsdc) {
        MockCase0MiltonUsdc mockCase0MiltonUsdcImplementation = new MockCase0MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase0MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        MockCase0MiltonUsdc miltonUsdc = MockCase0MiltonUsdc(address(miltonUsdcProxy));
        return miltonUsdc;
    }

    function prepareMockCase0MiltonUsdc(MockCase0MiltonUsdc miltonUsdc, address josephUsdc, address stanleyUsdc)
        public
    {
        miltonUsdc.setJoseph(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase0MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase0MiltonDai) {
        MockCase0MiltonDai mockCase0MiltonDaiImplementation = new MockCase0MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase0MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        MockCase0MiltonDai miltonDai = MockCase0MiltonDai(address(miltonDaiProxy));
        return miltonDai;
    }

    function prepareMockCase0MiltonDai(MockCase0MiltonDai miltonDai, address josephDai, address stanleyDai) public {
        miltonDai.setJoseph(josephDai);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    function getMockCase0Miltons(
        address iporOracle,
        address miltonSpreadModel,
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (MockCase0Miltons memory) {
        MockCase0Miltons memory mockCase0Miltons;
        mockCase0Miltons.mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]
        );
        mockCase0Miltons.mockCase0MiltonUsdc = getMockCase0MiltonUsdc(
            tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]
        );
        mockCase0Miltons.mockCase0MiltonDai = getMockCase0MiltonDai(
            tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]
        );
        return mockCase0Miltons;
    }

    function getMockCase0MiltonAddresses(address miltonUsdt, address miltonUsdc, address miltonDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory miltons = new address[](3);
        miltons[0] = miltonUsdt;
        miltons[1] = miltonUsdc;
        miltons[2] = miltonDai;
        return miltons;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase2MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase2MiltonUsdt) {
        MockCase2MiltonUsdt mockCase2MiltonUsdtImplementation = new MockCase2MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase2MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        MockCase2MiltonUsdt miltonUsdt = MockCase2MiltonUsdt(address(miltonUsdtProxy));
        return miltonUsdt;
    }

    function prepareMockCase2MiltonUsdt(MockCase2MiltonUsdt miltonUsdt, address josephUsdt, address stanleyUsdt)
        public
    {
        miltonUsdt.setJoseph(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase2MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase2MiltonUsdc) {
        MockCase2MiltonUsdc mockCase2MiltonUsdcImplementation = new MockCase2MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase2MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        MockCase2MiltonUsdc miltonUsdc = MockCase2MiltonUsdc(address(miltonUsdcProxy));
        return miltonUsdc;
    }

    function prepareMockCase2MiltonUsdc(MockCase2MiltonUsdc miltonUsdc, address josephUsdc, address stanleyUsdc)
        public
    {
        miltonUsdc.setJoseph(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase2MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase2MiltonDai) {
        MockCase2MiltonDai mockCase2MiltonDaiImplementation = new MockCase2MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase2MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        MockCase2MiltonDai miltonDai = MockCase2MiltonDai(address(miltonDaiProxy));
        return miltonDai;
    }

    function prepareMockCase2MiltonDai(MockCase2MiltonDai miltonDai, address josephDai, address stanleyDai) public {
        miltonDai.setJoseph(josephDai);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase3MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase3MiltonUsdt) {
        MockCase3MiltonUsdt mockCase3MiltonUsdtImplementation = new MockCase3MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase3MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        MockCase3MiltonUsdt miltonUsdt = MockCase3MiltonUsdt(address(miltonUsdtProxy));
        return miltonUsdt;
    }

    function prepareMockCase3MiltonUsdt(MockCase3MiltonUsdt miltonUsdt, address josephUsdt, address stanleyUsdt)
        public
    {
        miltonUsdt.setJoseph(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase3MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase3MiltonUsdc) {
        MockCase3MiltonUsdc mockCase3MiltonUsdcImplementation = new MockCase3MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase3MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        MockCase3MiltonUsdc miltonUsdc = MockCase3MiltonUsdc(address(miltonUsdcProxy));
        return miltonUsdc;
    }

    function prepareMockCase3MiltonUsdc(MockCase3MiltonUsdc miltonUsdc, address josephUsdc, address stanleyUsdc)
        public
    {
        miltonUsdc.setJoseph(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase3MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase3MiltonDai) {
        MockCase3MiltonDai mockCase3MiltonDaiImplementation = new MockCase3MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase3MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        MockCase3MiltonDai miltonDai = MockCase3MiltonDai(address(miltonDaiProxy));
        return miltonDai;
    }

    function prepareMockCase3MiltonDai(MockCase3MiltonDai miltonDai, address josephDai, address stanleyDai) public {
        miltonDai.setJoseph(josephDai);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase6MiltonUsdt(
        address deployer,
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ProxyTester, MockCase6MiltonUsdt) {
        ProxyTester miltonUsdtProxy = new ProxyTester();
        miltonUsdtProxy.setType("uups");
        MockCase6MiltonUsdt mockCase6MiltonUsdtFactory = new MockCase6MiltonUsdt();
        address miltonUsdtProxyAddress = miltonUsdtProxy.deploy(
            address(mockCase6MiltonUsdtFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );
        MockCase6MiltonUsdt mockCase6MiltonUsdt = MockCase6MiltonUsdt(miltonUsdtProxyAddress);
        return (miltonUsdtProxy, mockCase6MiltonUsdt);
    }

    function prepareMockCase6MiltonUsdt(
        MockCase6MiltonUsdt miltonUsdt,
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

    function getMockCase6MiltonUsdc(
        address deployer,
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ProxyTester, MockCase6MiltonUsdc) {
        ProxyTester miltonUsdcProxy = new ProxyTester();
        miltonUsdcProxy.setType("uups");
        MockCase6MiltonUsdc mockCase6MiltonUsdcFactory = new MockCase6MiltonUsdc();
        address miltonUsdcProxyAddress = miltonUsdcProxy.deploy(
            address(mockCase6MiltonUsdcFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                iporOracle,
                miltonStorageUsdc,
                miltonSpreadModel,
                stanleyUsdc
            )
        );
        MockCase6MiltonUsdc mockCase6MiltonUsdc = MockCase6MiltonUsdc(miltonUsdcProxyAddress);
        return (miltonUsdcProxy, mockCase6MiltonUsdc);
    }

    function prepareMockCase6MiltonUsdc(
        MockCase6MiltonUsdc miltonUsdc,
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

    function getMockCase6MiltonDai(
        address deployer,
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ProxyTester, MockCase6MiltonDai) {
        ProxyTester miltonDaiProxy = new ProxyTester();
        miltonDaiProxy.setType("uups");
        MockCase6MiltonDai mockCase6MiltonDaiFactory = new MockCase6MiltonDai();
        address miltonDaiProxyAddress = miltonDaiProxy.deploy(
            address(mockCase6MiltonDaiFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                iporOracle,
                miltonStorageDai,
                miltonSpreadModel,
                stanleyDai
            )
        );
        MockCase6MiltonDai mockCase6MiltonDai = MockCase6MiltonDai(miltonDaiProxyAddress);
        return (miltonDaiProxy, mockCase6MiltonDai);
    }

    function prepareMockCase6MiltonDai(
        MockCase6MiltonDai miltonDai,
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

    /// ------------------- Mock Cases Milton -------------------

    /// ------------------- Mock Cases Milton Spread -------------------
    function prepareMiltonSpreadBaseUsdt() public returns (MockBaseMiltonSpreadModelUsdt) {
        MockBaseMiltonSpreadModelUsdt mockBaseMiltonSpreadModelUsdt = new MockBaseMiltonSpreadModelUsdt();
        return mockBaseMiltonSpreadModelUsdt;
    }

    function prepareMiltonSpreadBaseUsdc() public returns (MockBaseMiltonSpreadModelUsdc) {
        MockBaseMiltonSpreadModelUsdc mockBaseMiltonSpreadModelUsdc = new MockBaseMiltonSpreadModelUsdc();
        return mockBaseMiltonSpreadModelUsdc;
    }

    function prepareMiltonSpreadBaseDai() public returns (MockBaseMiltonSpreadModelDai) {
        MockBaseMiltonSpreadModelDai mockBaseMiltonSpreadModelDai = new MockBaseMiltonSpreadModelDai();
        return mockBaseMiltonSpreadModelDai;
    }
    /// ------------------- Mock Cases Milton Spread -------------------

    /// ------------------- Milton Test Cases -------------------

    struct TestCaseWhenMiltonLostAndUserEarnedDai {
        uint256 openerUserLost;
        uint256 expectedMiltonUnderlyingTokenBalance;
        uint256 expectedOpenerUserUnderlyingTokenBalanceAfterClose;
        uint256 expectedCloserUserUnderlyingTokenBalanceAfterClose;
    }

    function getTestCaseWhenMiltonLostAndUserEarnedDai(
        uint256 openerUserLost,
        uint256 expectedMiltonUnderlyingTokenBalance,
        uint256 expectedOpenerUserUnderlyingTokenBalanceAfterClose,
        uint256 expectedCloserUserUnderlyingTokenBalanceAfterClose
    ) public pure returns (TestCaseWhenMiltonLostAndUserEarnedDai memory) {
        TestCaseWhenMiltonLostAndUserEarnedDai memory testCaseWhenMiltonLostAndUserEarned;
        testCaseWhenMiltonLostAndUserEarned.openerUserLost = openerUserLost;
        testCaseWhenMiltonLostAndUserEarned.expectedMiltonUnderlyingTokenBalance = expectedMiltonUnderlyingTokenBalance;
        testCaseWhenMiltonLostAndUserEarned.expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            expectedOpenerUserUnderlyingTokenBalanceAfterClose;
        testCaseWhenMiltonLostAndUserEarned.expectedCloserUserUnderlyingTokenBalanceAfterClose =
            expectedCloserUserUnderlyingTokenBalanceAfterClose;
        return testCaseWhenMiltonLostAndUserEarned;
    }
}
