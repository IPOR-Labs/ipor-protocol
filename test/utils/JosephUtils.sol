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

    struct ExchangeRateAndPayoff {
        uint256 initialExchangeRate;
        uint256 exchangeRateAfter28Days;
        uint256 exchangeRateAfter56DaysBeforeClose;
        int256 payoff1After28Days;
        int256 payoff2After28Days;
        int256 payoff1After56Days;
        int256 payoff2After56Days;
    }

    struct ExpectedJosephBalances {
        uint256 expectedMiltonBalance;
        uint256 expectedIpTokenBalance;
        uint256 expectedTokenBalance;
        uint256 expectedLiquidityPoolBalance;
    }

    function prepareJoseph(IJosephInternal joseph) public {
        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);
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

}
