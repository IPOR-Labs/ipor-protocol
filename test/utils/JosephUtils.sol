// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/interfaces/IJosephInternal.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/mocks/joseph/MockCase1JosephUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdc.sol";
import "../../contracts/mocks/joseph/MockCase1JosephUsdc.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase1JosephDai.sol";

contract JosephUtils is Test {
    function getItfJosephUsdt(
        address tokenUsdt,
        address ipTokenUsdt,
        address miltonUsdt,
        address miltonStorageUsdt,
        address stanleyUsdt
    ) public returns (ItfJosephUsdt) {
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

        return ItfJosephUsdt(address(josephUsdtProxy));
    }

    function getItfJosephUsdc(
        address tokenUsdc,
        address ipTokenUsdc,
        address miltonUsdc,
        address miltonStorageUsdc,
        address stanleyUsdc
    ) public returns (ItfJosephUsdc) {
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

        return ItfJosephUsdc(address(josephUsdcProxy));
    }

    function getItfJosephDai(
        address tokenDai,
        address ipTokenDai,
        address miltonDai,
        address miltonStorageDai,
        address stanleyDai
    ) public returns (ItfJosephDai) {
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

        return ItfJosephDai(address(josephDaiProxy));
    }

    function prepareJoseph(IJosephInternal joseph) public {
        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);
    }
}
