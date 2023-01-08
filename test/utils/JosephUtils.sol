// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/mocks/joseph/MockCase1JosephUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdc.sol";
import "../../contracts/mocks/joseph/MockCase1JosephUsdc.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase1JosephDai.sol";

contract JosephUtils is Test {
    /// ------------------- JOSEPH -------------------
    struct ItfJosephs {
        ProxyTester itfJosephUsdtProxy;
        ItfJosephUsdt itfJosephUsdt;
        ProxyTester itfJosephUsdcProxy;
        ItfJosephUsdc itfJosephUsdc;
        ProxyTester itfJosephDaiProxy;
        ItfJosephDai itfJosephDai;
    }

    struct MockCase0Josephs {
        ProxyTester mockCase0JosephUsdtProxy;
        MockCase0JosephUsdt mockCase0JosephUsdt;
        ProxyTester mockCase0JosephUsdcProxy;
        MockCase0JosephUsdc mockCase0JosephUsdc;
        ProxyTester mockCase0JosephDaiProxy;
        MockCase0JosephDai mockCase0JosephDai;
    }
    /// ------------------- JOSEPH -------------------
    /// ---------------------- ITFJOSEPH ----------------------

    function getItfJosephUsdt(
        address deployer,
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ProxyTester, ItfJosephUsdt) {
        ProxyTester josephUsdtProxy = new ProxyTester();
        josephUsdtProxy.setType("uups");
        ItfJosephUsdt josephUsdtFactory = new ItfJosephUsdt();
        address josephUsdtProxyAddress = josephUsdtProxy.deploy(
            address(josephUsdtFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                ipTokenUsdt,
                miltonUsdt,
                miltonStorageUsdt,
                stanleyUsdt
            )
        );
        ItfJosephUsdt itfJosephUsdt = ItfJosephUsdt(josephUsdtProxyAddress);
        return (josephUsdtProxy, itfJosephUsdt);
    }

    function prepareItfJosephUsdt(ItfJosephUsdt itfJosephUsdt, address josephUsdtProxy) public {
        vm.prank(josephUsdtProxy);
        itfJosephUsdt.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephUsdtProxy);
        itfJosephUsdt.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getItfJosephUsdc(
        address deployer,
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ProxyTester, ItfJosephUsdc) {
        ProxyTester josephUsdcProxy = new ProxyTester();
        josephUsdcProxy.setType("uups");
        ItfJosephUsdc josephUsdcFactory = new ItfJosephUsdc();
        address josephUsdcProxyAddress = josephUsdcProxy.deploy(
            address(josephUsdcFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                ipTokenUsdc,
                miltonUsdc,
                miltonStorageUsdc,
                stanleyUsdc
            )
        );
        ItfJosephUsdc itfJosephUsdc = ItfJosephUsdc(josephUsdcProxyAddress);
        return (josephUsdcProxy, itfJosephUsdc);
    }

    function prepareItfJosephUsdc(ItfJosephUsdc itfJosephUsdc, address josephUsdcProxy) public {
        vm.prank(josephUsdcProxy);
        itfJosephUsdc.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephUsdcProxy);
        itfJosephUsdc.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getItfJosephDai(
        address deployer,
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ProxyTester, ItfJosephDai) {
        ProxyTester josephDaiProxy = new ProxyTester();
        josephDaiProxy.setType("uups");
        ItfJosephDai josephDaiFactory = new ItfJosephDai();
        address josephDaiProxyAddress = josephDaiProxy.deploy(
            address(josephDaiFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                ipTokenDai,
                miltonDai,
                miltonStorageDai,
                stanleyDai
            )
        );
        ItfJosephDai itfJosephDai = ItfJosephDai(josephDaiProxyAddress);
        return (josephDaiProxy, itfJosephDai);
    }

    function prepareItfJosephDai(ItfJosephDai itfJosephDai, address josephDaiProxy) public {
        vm.prank(josephDaiProxy);
        itfJosephDai.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephDaiProxy);
        itfJosephDai.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getItfJosephAddresses(address josephUsdt, address josephUsdc, address josephDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory josephs = new address[](3);
        josephs[0] = josephUsdt;
        josephs[1] = josephUsdc;
        josephs[2] = josephDai;
        return josephs;
    }

    function getItfJosephs(
        address deployer,
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (ItfJosephs memory) {
        ItfJosephs memory itfJosephs;
        (itfJosephs.itfJosephUsdtProxy, itfJosephs.itfJosephUsdt) = getItfJosephUsdt(
            deployer,
            tokenAddresses[0],
            ipTokenAddresses[0],
            miltonAddresses[0],
            miltonStorageAddresses[0],
            stanleyAddresses[0]
        );
        (itfJosephs.itfJosephUsdcProxy, itfJosephs.itfJosephUsdc) = getItfJosephUsdc(
            deployer,
            tokenAddresses[1],
            ipTokenAddresses[1],
            miltonAddresses[1],
            miltonStorageAddresses[1],
            stanleyAddresses[1]
        );
        (itfJosephs.itfJosephDaiProxy, itfJosephs.itfJosephDai) = getItfJosephDai(
            deployer,
            tokenAddresses[2],
            ipTokenAddresses[2],
            miltonAddresses[2],
            miltonStorageAddresses[2],
            stanleyAddresses[2]
        );
        return itfJosephs;
    }
    /// ---------------------- ITFJOSEPH ----------------------

    /// ---------------------- Mock Cases Joseph ----------------------
    function getMockCase0JosephUsdt(
        address deployer,
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ProxyTester, MockCase0JosephUsdt) {
        ProxyTester josephUsdtProxy = new ProxyTester();
        josephUsdtProxy.setType("uups");
        MockCase0JosephUsdt josephUsdtFactory = new MockCase0JosephUsdt();
        address josephUsdtProxyAddress = josephUsdtProxy.deploy(
            address(josephUsdtFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                ipTokenUsdt,
                miltonUsdt,
                miltonStorageUsdt,
                stanleyUsdt
            )
        );
        MockCase0JosephUsdt mockCase0Joseph = MockCase0JosephUsdt(josephUsdtProxyAddress);
        return (josephUsdtProxy, mockCase0Joseph);
    }

    function prepareMockCase0JosephUsdt(MockCase0JosephUsdt mockCase0JosephUsdt, address josephUsdtProxy) public {
        vm.prank(josephUsdtProxy);
        mockCase0JosephUsdt.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephUsdtProxy);
        mockCase0JosephUsdt.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephUsdc(
        address deployer,
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ProxyTester, MockCase0JosephUsdc) {
        ProxyTester josephUsdcProxy = new ProxyTester();
        josephUsdcProxy.setType("uups");
        MockCase0JosephUsdc josephUsdcFactory = new MockCase0JosephUsdc();
        address josephUsdcProxyAddress = josephUsdcProxy.deploy(
            address(josephUsdcFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                ipTokenUsdc,
                miltonUsdc,
                miltonStorageUsdc,
                stanleyUsdc
            )
        );
        MockCase0JosephUsdc mockCase0JosephUsdc = MockCase0JosephUsdc(josephUsdcProxyAddress);
        return (josephUsdcProxy, mockCase0JosephUsdc);
    }

    function prepareMockCase0JosephUsdc(MockCase0JosephUsdc mockCase0JosephUsdc, address josephUsdcProxy) public {
        vm.prank(josephUsdcProxy);
        mockCase0JosephUsdc.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephUsdcProxy);
        mockCase0JosephUsdc.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephDai(
        address deployer,
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ProxyTester, MockCase0JosephDai) {
        ProxyTester josephDaiProxy = new ProxyTester();
        josephDaiProxy.setType("uups");
        MockCase0JosephDai josephDaiFactory = new MockCase0JosephDai();
        address josephDaiProxyAddress = josephDaiProxy.deploy(
            address(josephDaiFactory),
            deployer,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                ipTokenDai,
                miltonDai,
                miltonStorageDai,
                stanleyDai
            )
        );
        MockCase0JosephDai mockCase0JosephDai = MockCase0JosephDai(josephDaiProxyAddress);
        return (josephDaiProxy, mockCase0JosephDai);
    }

    function prepareMockCase0JosephDai(MockCase0JosephDai mockCase0JosephDai, address josephDaiProxy) public {
        vm.prank(josephDaiProxy);
        mockCase0JosephDai.setMaxLiquidityPoolBalance(10 * 10 ** 6); // 10M, USD_10_000_000
        vm.prank(josephDaiProxy);
        mockCase0JosephDai.setMaxLpAccountContribution(1 * 10 ** 6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephAddresses(address josephUsdt, address josephUsdc, address josephDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory josephs = new address[](3);
        josephs[0] = josephUsdt;
        josephs[1] = josephUsdc;
        josephs[2] = josephDai;
        return josephs;
    }

    function getMockCase0Josephs(
        address deployer,
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (MockCase0Josephs memory) {
        MockCase0Josephs memory mockCase0Josephs;
        (mockCase0Josephs.mockCase0JosephUsdtProxy, mockCase0Josephs.mockCase0JosephUsdt) = getMockCase0JosephUsdt(
            deployer,
            tokenAddresses[0],
            ipTokenAddresses[0],
            miltonAddresses[0],
            miltonStorageAddresses[0],
            stanleyAddresses[0]
        );
        (mockCase0Josephs.mockCase0JosephUsdcProxy, mockCase0Josephs.mockCase0JosephUsdc) = getMockCase0JosephUsdc(
            deployer,
            tokenAddresses[1],
            ipTokenAddresses[1],
            miltonAddresses[1],
            miltonStorageAddresses[1],
            stanleyAddresses[1]
        );
        (mockCase0Josephs.mockCase0JosephDaiProxy, mockCase0Josephs.mockCase0JosephDai) = getMockCase0JosephDai(
            deployer,
            tokenAddresses[2],
            ipTokenAddresses[2],
            miltonAddresses[2],
            miltonStorageAddresses[2],
            stanleyAddresses[2]
        );
        return mockCase0Josephs;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase1JosephUsdt() public returns (MockCase1JosephUsdt) {
        MockCase1JosephUsdt mockJoseph = new MockCase1JosephUsdt();
        return mockJoseph;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase0JosephUsdc() public returns (MockCase0JosephUsdc) {
        MockCase0JosephUsdc mockJoseph = new MockCase0JosephUsdc();
        return mockJoseph;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase1JosephUsdc() public returns (MockCase1JosephUsdc) {
        MockCase1JosephUsdc mockJoseph = new MockCase1JosephUsdc();
        return mockJoseph;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase0JosephDai() public returns (MockCase0JosephDai) {
        MockCase0JosephDai mockJoseph = new MockCase0JosephDai();
        return mockJoseph;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase1JosephDai() public returns (MockCase1JosephDai) {
        MockCase1JosephDai mockJoseph = new MockCase1JosephDai();
        return mockJoseph;
    }
    /// ---------------------- Mock Cases Joseph ----------------------
}
