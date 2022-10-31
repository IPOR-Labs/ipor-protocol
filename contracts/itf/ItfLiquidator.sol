// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../interfaces/IMiltonStorage.sol";
import "./types/ItfMiltonTypes.sol";
import "./ItfMilton.sol";
import "../libraries/errors/MiltonErrors.sol";

contract ItfLiquidator {

    ItfMilton private _milton;
    IMiltonStorage private _miltonStorage;

    constructor(address miltonAddress, address miltonStorage) {
        _milton = ItfMilton(miltonAddress);
        _miltonStorage = IMiltonStorage(miltonStorage);
    }

    function itfLiquidate(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        uint256 closeTimestamp
    )
        external
        returns (
            uint256 payoutForLiquidatorPayFixed,
            MiltonTypes.IporSwapClosingResult[] memory payFixedClosedSwaps,
            uint256 payoutForLiquidatorReceiveFixed,
            MiltonTypes.IporSwapClosingResult[] memory receiveFixedClosedSwaps
        )
    {
        if (payFixedSwapIds.length > 0) {
            payFixedClosedSwaps = new MiltonTypes.IporSwapClosingResult[](payFixedSwapIds.length);
            for (uint256 i = 0; i < payFixedSwapIds.length; i++) {
                uint256 swapId = payFixedSwapIds[i];
                IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapPayFixed(swapId);
                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                    try _milton.itfCloseSwapPayFixed(swapId, closeTimestamp) {
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
                    } catch {
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                    }
                } else {
                    payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                }
            }
        }
        if (receiveFixedSwapIds.length > 0) {
            receiveFixedClosedSwaps = new MiltonTypes.IporSwapClosingResult[](
                receiveFixedSwapIds.length
            );
            for (uint256 i = 0; i < receiveFixedSwapIds.length; i++) {
                uint256 swapId = receiveFixedSwapIds[i];
                IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapReceiveFixed(
                    swapId
                );
                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                    try _milton.itfCloseSwapReceiveFixed(swapId, closeTimestamp) {
                        receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(
                            swapId,
                            true
                        );
                    } catch {
                        receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(
                            swapId,
                            false
                        );
                    }
                } else {
                    receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                }
            }
        }
    }

}
