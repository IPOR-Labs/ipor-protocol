// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/interfaces/IJosephInternal.sol";
import "../utils/TestConstants.sol";
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
        ItfJosephUsdt itfJosephUsdt;
        ItfJosephUsdc itfJosephUsdc;
        ItfJosephDai itfJosephDai;
    }

    struct MockCase0Josephs {
        MockCase0JosephUsdt mockCase0JosephUsdt;
        MockCase0JosephUsdc mockCase0JosephUsdc;
        MockCase0JosephDai mockCase0JosephDai;
    }

    function prepareJoseph(IJosephInternal joseph) public {
        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);
    }
    /// ------------------- JOSEPH -------------------
    /// ---------------------- ITFJOSEPH ----------------------

    function getItfJosephUsdt(
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ItfJosephUsdt) {
        ItfJosephUsdt josephUsdtImplementation = new ItfJosephUsdt();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdtImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdt, ipTokenUsdt, miltonUsdt, miltonStorageUsdt, stanleyUsdt));
        ItfJosephUsdt itfJosephUsdt = ItfJosephUsdt(address(josephProxy));
        return itfJosephUsdt;
    }

    function getItfJosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ItfJosephUsdc) {
        ItfJosephUsdc josephUsdcImplementation = new ItfJosephUsdc();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdcImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdc, ipTokenUsdc, miltonUsdc, miltonStorageUsdc, stanleyUsdc));
        ItfJosephUsdc itfJosephUsdc = ItfJosephUsdc(address(josephProxy));
        return itfJosephUsdc;
    }

    function getItfJosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ItfJosephDai) {
        ItfJosephDai josephDaiImplementation = new ItfJosephDai();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephDaiImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenDai, ipTokenDai, miltonDai, miltonStorageDai, stanleyDai));
        ItfJosephDai itfJosephDai = ItfJosephDai(address(josephProxy));
        return itfJosephDai;
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
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (ItfJosephs memory) {
        ItfJosephs memory itfJosephs;
        itfJosephs.itfJosephUsdt = getItfJosephUsdt(
            tokenAddresses[0], ipTokenAddresses[0], miltonAddresses[0], miltonStorageAddresses[0], stanleyAddresses[0]
        );
        itfJosephs.itfJosephUsdc = getItfJosephUsdc(
            tokenAddresses[1], ipTokenAddresses[1], miltonAddresses[1], miltonStorageAddresses[1], stanleyAddresses[1]
        );
        itfJosephs.itfJosephDai = getItfJosephDai(
            tokenAddresses[2], ipTokenAddresses[2], miltonAddresses[2], miltonStorageAddresses[2], stanleyAddresses[2]
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
    ) public returns (MockCase0JosephUsdt) {
        MockCase0JosephUsdt josephUsdtImplementation = new MockCase0JosephUsdt();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdtImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdt, ipTokenUsdt, miltonUsdt, miltonStorageUsdt, stanleyUsdt));
        MockCase0JosephUsdt mockCase0JosephUsdt = MockCase0JosephUsdt(address(josephProxy));
        return mockCase0JosephUsdt;
    }

    function getMockCase0JosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (MockCase0JosephUsdc) {
        MockCase0JosephUsdc josephUsdcImplementation = new MockCase0JosephUsdc();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdcImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdc, ipTokenUsdc, miltonUsdc, miltonStorageUsdc, stanleyUsdc));
        MockCase0JosephUsdc mockCase0JosephUsdc = MockCase0JosephUsdc(address(josephProxy));
        return mockCase0JosephUsdc;
    }

    function getMockCase0JosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (MockCase0JosephDai) {
        MockCase0JosephDai josephDaiImplementation = new MockCase0JosephDai();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephDaiImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenDai, ipTokenDai, miltonDai, miltonStorageDai, stanleyDai));
        MockCase0JosephDai mockCase0JosephDai = MockCase0JosephDai(address(josephProxy));
        return mockCase0JosephDai;
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
        address[] memory tokenAddresses,
        address[] memory ipTokenAddresses,
        address[] memory miltonAddresses,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (MockCase0Josephs memory) {
        MockCase0Josephs memory mockCase0Josephs;
        mockCase0Josephs.mockCase0JosephUsdt = getMockCase0JosephUsdt(
            tokenAddresses[0], ipTokenAddresses[0], miltonAddresses[0], miltonStorageAddresses[0], stanleyAddresses[0]
        );
        mockCase0Josephs.mockCase0JosephUsdc = getMockCase0JosephUsdc(
            tokenAddresses[1], ipTokenAddresses[1], miltonAddresses[1], miltonStorageAddresses[1], stanleyAddresses[1]
        );
        mockCase0Josephs.mockCase0JosephDai = getMockCase0JosephDai(
            tokenAddresses[2], ipTokenAddresses[2], miltonAddresses[2], miltonStorageAddresses[2], stanleyAddresses[2]
        );
        return mockCase0Josephs;
    }

    /// ------------------------------------------------------------------------------------

    /// ---------------------- Mock Cases Joseph ----------------------
}
