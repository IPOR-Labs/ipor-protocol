// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../interfaces/IAmmStorage.sol";
import "./types/ItfAmmTreasuryTypes.sol";
import "../libraries/errors/AmmErrors.sol";

contract ItfLiquidator {

//    ItfAmmTreasury private _ammTreasury;
//    IAmmStorage private _ammStorage;

    constructor(address ammTreasuryAddress, address ammStorage) {
//        _ammTreasury = ItfAmmTreasury(ammTreasuryAddress);
//        _ammStorage = IAmmStorage(ammStorage);
    }
//
//    function itfLiquidate(
//        uint256[] calldata payFixedSwapIds,
//        uint256[] calldata receiveFixedSwapIds,
//        uint256 closeTimestamp
//    )
//        external
//        returns (
//            AmmTypes.IporSwapClosingResult[] memory payFixedClosedSwaps,
//            AmmTypes.IporSwapClosingResult[] memory receiveFixedClosedSwaps
//        )
//    {
//        ItfAmmTreasury ammTreasury = _ammTreasury;
//        IAmmStorage ammStorage = _ammStorage;
//        uint256 payFixedSwapIdsLength = payFixedSwapIds.length;
//        uint256 receiveFixedSwapIdsLength = receiveFixedSwapIds.length;
//        uint256 swapId;
//        if (payFixedSwapIdsLength > 0) {
//            payFixedClosedSwaps = new AmmTypes.IporSwapClosingResult[](payFixedSwapIdsLength);
//            for (uint256 i; i < payFixedSwapIdsLength; ++i) {
//                swapId = payFixedSwapIds[i];
//                IporTypes.IporSwapMemory memory iporSwap = ammStorage.getSwapPayFixed(swapId);
//                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
//                    try ammTreasury.itfCloseSwapPayFixed(swapId, closeTimestamp) {
//                        payFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, true);
//                    } catch {
//                        payFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
//                    }
//                } else {
//                    payFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
//                }
//            }
//        }
//        if (receiveFixedSwapIdsLength > 0) {
//            receiveFixedClosedSwaps = new AmmTypes.IporSwapClosingResult[](
//                receiveFixedSwapIdsLength
//            );
//            for (uint256 i; i < receiveFixedSwapIdsLength; ++i) {
//                swapId = receiveFixedSwapIds[i];
//                IporTypes.IporSwapMemory memory iporSwap = _ammStorage.getSwapReceiveFixed(
//                    swapId
//                );
//                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
//                    try ammTreasury.itfCloseSwapReceiveFixed(swapId, closeTimestamp) {
//                        receiveFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(
//                            swapId,
//                            true
//                        );
//                    } catch {
//                        receiveFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(
//                            swapId,
//                            false
//                        );
//                    }
//                } else {
//                    receiveFixedClosedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
//                }
//            }
//        }
//    }

}
