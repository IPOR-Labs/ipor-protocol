// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";


contract ItfHelper {

    address internal immutable _router;
    address internal immutable _usdt;
    address internal immutable _usdc;
    address internal immutable _dai;

    constructor(address router, address usdt, address usdc, address dai) {
        _router = router;
        _usdt = usdt;
        _usdc = usdc;
        _dai = dai;
    }

    function getRouter() external view returns (address) {
        return _router;
    }

    function getPnl(address account, address asset) external view returns (int256){
        uint256 totalCount=1;
        int256 pnl;
        uint256 offset;
        IAmmSwapsLens.IporSwap[] memory openSwaps;

        while (offset < totalCount) {
            (totalCount, openSwaps) = IAmmSwapsLens(_router).getSwaps(
                asset,
                account,
                offset,
                50
            );
            if (totalCount == 0) {
                break;
            }
            offset += openSwaps.length;

            AmmTypes.ClosingSwapDetails memory swapDetails;
            for (uint i; i < openSwaps.length; ++i) {
                swapDetails = IAmmCloseSwapLens(_router).getClosingSwapDetails(asset, AmmTypes.SwapDirection(openSwaps[i].direction), openSwaps[i].id, block.timestamp);
                pnl += swapDetails.pnlValue;
            }
        }
        return pnl;
    }
}