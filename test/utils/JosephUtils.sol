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

    struct ExchangeRateAndPayoff {
        uint256 initialExchangeRate;
        uint256 exchangeRateAfter28Days;
        uint256 exchangeRateAfter56DaysBeforeClose;
        int256 payoff1After28Days;
        int256 payoff2After28Days;
        int256 payoff1After56Days;
        int256 payoff2After56Days;
    }

    function prepareJoseph(IJosephInternal joseph) public {
        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);
    }

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
        return ItfJosephUsdt(address(josephProxy));
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
        return ItfJosephUsdc(address(josephProxy));
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
        return ItfJosephDai(address(josephProxy));
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
        return MockCase0JosephUsdt(address(josephProxy));
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
        return MockCase0JosephUsdc(address(josephProxy));
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
        return MockCase0JosephDai(address(josephProxy));
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

    function getMockCase1JosephUsdt(
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (MockCase1JosephUsdt) {
        MockCase1JosephUsdt josephUsdtImplementation = new MockCase1JosephUsdt();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdtImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdt, ipTokenUsdt, miltonUsdt, miltonStorageUsdt, stanleyUsdt));
        return MockCase1JosephUsdt(address(josephProxy));
    }

    function getMockCase1JosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (MockCase1JosephUsdc) {
        MockCase1JosephUsdc josephUsdcImplementation = new MockCase1JosephUsdc();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephUsdcImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenUsdc, ipTokenUsdc, miltonUsdc, miltonStorageUsdc, stanleyUsdc));
        return MockCase1JosephUsdc(address(josephProxy));
    }

    function getMockCase1JosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (MockCase1JosephDai) {
        MockCase1JosephDai josephDaiImplementation = new MockCase1JosephDai();
        ERC1967Proxy josephProxy =
        new ERC1967Proxy(address(josephDaiImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, tokenDai, ipTokenDai, miltonDai, miltonStorageDai, stanleyDai));
        return MockCase1JosephDai(address(josephProxy));
    }

}
