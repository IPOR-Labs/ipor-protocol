// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "../../contracts/amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../fork/TestForkCommons.sol";

contract IporClient {
    address internal _iporProtocolRouter;

    constructor(address iporProtocolRouter) {
        _iporProtocolRouter = iporProtocolRouter;
    }

    function openIporSwapPayFixed28DaysEth(
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) public payable returns (uint256) {
        return
            IAmmOpenSwapServiceStEth(_iporProtocolRouter).openSwapPayFixed28daysStEth{value: msg.value}(
                msg.sender,
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                msg.value,
                1e18,
                10e18,
                riskIndicatorsInputs
            );
    }

    fallback(bytes calldata input) external payable returns (bytes memory output) {
        console2.log("Fallback executed!");
        output = new bytes(10);
    }
}
