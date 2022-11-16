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
        uint256[] calldata payFixedSwapIds,
        uint256[] calldata receiveFixedSwapIds,
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
        ItfMilton milton = _milton;
        IMiltonStorage miltonStorage = _miltonStorage;
        uint256 payFixedSwapIdsLength = payFixedSwapIds.length;
        uint256 receiveFixedSwapIdsLength = receiveFixedSwapIds.length;
        if (payFixedSwapIdsLength > 0) {
            payFixedClosedSwaps = new MiltonTypes.IporSwapClosingResult[](payFixedSwapIdsLength);
            uint256 swapId; 
            for (uint256 i; i < payFixedSwapIdsLength; ++i) {
                swapId = payFixedSwapIds[i];
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId);
                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                    try milton.itfCloseSwapPayFixed(swapId, closeTimestamp) {
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
                    } catch {
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                    }
                } else {
                    payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                }
            }
        }
        if (receiveFixedSwapIdsLength > 0) {
            receiveFixedClosedSwaps = new MiltonTypes.IporSwapClosingResult[](
                receiveFixedSwapIdsLength
            );
            uint256 swapId;
            for (uint256 i; i < receiveFixedSwapIdsLength; ++i) {
                swapId = receiveFixedSwapIds[i];
                IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapReceiveFixed(
                    swapId
                );
                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                    try milton.itfCloseSwapReceiveFixed(swapId, closeTimestamp) {
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
