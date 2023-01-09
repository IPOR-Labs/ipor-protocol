// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
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
        ERC1967Proxy itfJosephUsdtProxy;
        ItfJosephUsdt itfJosephUsdt;
        ERC1967Proxy itfJosephUsdcProxy;
        ItfJosephUsdc itfJosephUsdc;
        ERC1967Proxy itfJosephDaiProxy;
        ItfJosephDai itfJosephDai;
    }

    struct MockCase0Josephs {
        ERC1967Proxy mockCase0JosephUsdtProxy;
        MockCase0JosephUsdt mockCase0JosephUsdt;
        ERC1967Proxy mockCase0JosephUsdcProxy;
        MockCase0JosephUsdc mockCase0JosephUsdc;
        ERC1967Proxy mockCase0JosephDaiProxy;
        MockCase0JosephDai mockCase0JosephDai;
    }

    /// ------------------- JOSEPH -------------------
    /// ---------------------- ITFJOSEPH ----------------------

    function getItfJosephUsdt(
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, ItfJosephUsdt) {
        ItfJosephUsdt josephUsdtImpl = new ItfJosephUsdt();

        ERC1967Proxy josephUsdtProxy = new ERC1967Proxy(
            address(josephUsdtImpl),
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

        ItfJosephUsdt itfJosephUsdt = ItfJosephUsdt(address(josephUsdtProxy));
        return (josephUsdtProxy, itfJosephUsdt);
    }

    function prepareItfJosephUsdt(ItfJosephUsdt itfJosephUsdt, address josephUsdtProxy) public {
        vm.prank(josephUsdtProxy);
        itfJosephUsdt.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephUsdtProxy);
        itfJosephUsdt.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getItfJosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, ItfJosephUsdc) {
        ItfJosephUsdc josephUsdcImpl = new ItfJosephUsdc();
        ERC1967Proxy josephUsdcProxy = new ERC1967Proxy(
            address(josephUsdcImpl),
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
        ItfJosephUsdc itfJosephUsdc = ItfJosephUsdc(address(josephUsdcProxy));
        return (josephUsdcProxy, itfJosephUsdc);
    }

    function prepareItfJosephUsdc(ItfJosephUsdc itfJosephUsdc, address josephUsdcProxy) public {
        vm.prank(josephUsdcProxy);
        itfJosephUsdc.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephUsdcProxy);
        itfJosephUsdc.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getItfJosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ERC1967Proxy, ItfJosephDai) {
        ItfJosephDai josephDaiImpl = new ItfJosephDai();
        ERC1967Proxy josephDaiProxy = new ERC1967Proxy(
            address(josephDaiImpl),
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
        ItfJosephDai itfJosephDai = ItfJosephDai(address(josephDaiProxy));
        return (josephDaiProxy, itfJosephDai);
    }

    function prepareItfJosephDai(ItfJosephDai itfJosephDai, address josephDaiProxy) public {
        vm.prank(josephDaiProxy);
        itfJosephDai.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephDaiProxy);
        itfJosephDai.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getItfJosephAddresses(
        address josephUsdt,
        address josephUsdc,
        address josephDai
    ) public pure returns (address[] memory) {
        address[] memory josephs = new address[](3);
        josephs[0] = josephUsdt;
        josephs[1] = josephUsdc;
        josephs[2] = josephDai;
        return josephs;
    }

    function getItfJosephs(
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (ItfJosephs memory) {
        ItfJosephs memory itfJosephs;
        (itfJosephs.itfJosephUsdtProxy, itfJosephs.itfJosephUsdt) = getItfJosephUsdt(
            tokenAddresses[0],
            ipTokenAddresses[0],
            miltonAddresses[0],
            miltonStorageAddresses[0],
            stanleyAddresses[0]
        );
        (itfJosephs.itfJosephUsdcProxy, itfJosephs.itfJosephUsdc) = getItfJosephUsdc(
            tokenAddresses[1],
            ipTokenAddresses[1],
            miltonAddresses[1],
            miltonStorageAddresses[1],
            stanleyAddresses[1]
        );
        (itfJosephs.itfJosephDaiProxy, itfJosephs.itfJosephDai) = getItfJosephDai(
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
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, MockCase0JosephUsdt) {
        MockCase0JosephUsdt josephUsdtImpl = new MockCase0JosephUsdt();
        ERC1967Proxy josephUsdtProxy = new ERC1967Proxy(
            address(josephUsdtImpl),
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
        MockCase0JosephUsdt mockCase0Joseph = MockCase0JosephUsdt(address(josephUsdtProxy));
        return (josephUsdtProxy, mockCase0Joseph);
    }

    function prepareMockCase0JosephUsdt(
        MockCase0JosephUsdt mockCase0JosephUsdt,
        address josephUsdtProxy
    ) public {
        vm.prank(josephUsdtProxy);
        mockCase0JosephUsdt.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephUsdtProxy);
        mockCase0JosephUsdt.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, MockCase0JosephUsdc) {
        MockCase0JosephUsdc josephUsdcImpl = new MockCase0JosephUsdc();
        ERC1967Proxy josephUsdcProxy = new ERC1967Proxy(
            address(josephUsdcImpl),
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
        MockCase0JosephUsdc mockCase0JosephUsdc = MockCase0JosephUsdc(address(josephUsdcProxy));
        return (josephUsdcProxy, mockCase0JosephUsdc);
    }

    function prepareMockCase0JosephUsdc(
        MockCase0JosephUsdc mockCase0JosephUsdc,
        address josephUsdcProxy
    ) public {
        vm.prank(josephUsdcProxy);
        mockCase0JosephUsdc.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephUsdcProxy);
        mockCase0JosephUsdc.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ERC1967Proxy, MockCase0JosephDai) {
        MockCase0JosephDai josephDaiImpl = new MockCase0JosephDai();
        ERC1967Proxy josephDaiProxy = new ERC1967Proxy(
            address(josephDaiImpl),
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
        MockCase0JosephDai mockCase0JosephDai = MockCase0JosephDai(address(josephDaiProxy));
        return (josephDaiProxy, mockCase0JosephDai);
    }

    function prepareMockCase0JosephDai(
        MockCase0JosephDai mockCase0JosephDai,
        address josephDaiProxy
    ) public {
        vm.prank(josephDaiProxy);
        mockCase0JosephDai.setMaxLiquidityPoolBalance(10 * 10**6); // 10M, USD_10_000_000
        vm.prank(josephDaiProxy);
        mockCase0JosephDai.setMaxLpAccountContribution(1 * 10**6); // 1M, USD_1_000_000
    }

    function getMockCase0JosephAddresses(
        address josephUsdt,
        address josephUsdc,
        address josephDai
    ) public pure returns (address[] memory) {
        address[] memory josephs = new address[](3);
        josephs[0] = josephUsdt;
        josephs[1] = josephUsdc;
        josephs[2] = josephDai;
        return josephs;
    }

    function getMockCase0Josephs(
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (MockCase0Josephs memory) {
        MockCase0Josephs memory mockCase0Josephs;
        (
            mockCase0Josephs.mockCase0JosephUsdtProxy,
            mockCase0Josephs.mockCase0JosephUsdt
        ) = getMockCase0JosephUsdt(
            tokenAddresses[0],
            ipTokenAddresses[0],
            miltonAddresses[0],
            miltonStorageAddresses[0],
            stanleyAddresses[0]
        );
        (
            mockCase0Josephs.mockCase0JosephUsdcProxy,
            mockCase0Josephs.mockCase0JosephUsdc
        ) = getMockCase0JosephUsdc(
            tokenAddresses[1],
            ipTokenAddresses[1],
            miltonAddresses[1],
            miltonStorageAddresses[1],
            stanleyAddresses[1]
        );
        (
            mockCase0Josephs.mockCase0JosephDaiProxy,
            mockCase0Josephs.mockCase0JosephDai
        ) = getMockCase0JosephDai(
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
