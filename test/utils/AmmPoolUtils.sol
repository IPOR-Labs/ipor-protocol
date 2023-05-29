// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/AmmTreasury.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/oracles/IporOracle.sol";

contract AmmPoolUtils is Test {
    struct ExchangeRateAndPayoff {
        uint256 initialExchangeRate;
        uint256 exchangeRateAfter28Days;
        uint256 exchangeRateAfter56DaysBeforeClose;
        int256 payoff1After28Days;
        int256 payoff2After28Days;
        int256 payoff1After56Days;
        int256 payoff2After56Days;
    }

    function calculateSoap(
        address asset,
        address from,
        IporOracle iporOracle,
        AmmStorage ammStorage
    )
        public
        returns (
            int256,
            int256,
            int256
        )
    {
        vm.prank(from);
        IporTypes.AccruedIpor memory accruedIpor = iporOracle.getAccruedIndex(block.timestamp, asset);
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = ammStorage.calculateSoap(
            accruedIpor.ibtPrice,
            block.timestamp
        );
        return (soapPayFixed, soapReceiveFixed, soap);
    }
}
