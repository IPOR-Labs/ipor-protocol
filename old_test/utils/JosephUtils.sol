// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@ipor-protocol/contracts/interfaces/IJosephInternal.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/contracts/itf/ItfJoseph.sol";

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
        uint256 expectedAmmTreasuryBalance;
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
        address ammTreasuryUsdc,
        address ammStorageUsdc,
        address assetManagementUsdc
    ) public returns (ItfJoseph) {
        ItfJoseph josephUsdcImplementation = new ItfJoseph(6, true);
        ERC1967Proxy josephProxy = new ERC1967Proxy(
            address(josephUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                ipTokenUsdc,
                ammTreasuryUsdc,
                ammStorageUsdc,
                assetManagementUsdc
            )
        );
        return ItfJoseph(address(josephProxy));
    }

    function getMockCase0JosephDai(
        address tokenDai,
        address ipTokenDai,
        address ammTreasuryDai,
        address ammStorageDai,
        address assetManagementDai
    ) public returns (ItfJoseph) {
        ItfJoseph josephDaiImplementation = new ItfJoseph(18, true);
        ERC1967Proxy josephProxy = new ERC1967Proxy(
            address(josephDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                ipTokenDai,
                ammTreasuryDai,
                ammStorageDai,
                assetManagementDai
            )
        );
        return ItfJoseph(address(josephProxy));
    }
}
