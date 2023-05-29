// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/amm/spread/ISpreadCloseSwapService.sol";
import "contracts/libraries/errors/IporErrors.sol";

contract MockSpreadCloseSwapService is ISpreadCloseSwapService {

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI"));
        require(usdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC"));
        require(usdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT"));
        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function timeWeightedNotionalUpdateOnClose(
        address asset,
        uint256 direction,
        AmmTypes.SwapDuration duration,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external {
        console2.log("MockSpreadCloseSwapService");
    }

}