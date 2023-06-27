// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "../interfaces/IAmmStorage.sol";
import "../libraries/errors/IporErrors.sol";

contract ItfLiquidator {

//    ItfAmmTreasury private _ammTreasury;
//    IAmmStorage private _ammStorage;

    constructor(address ammTreasuryAddress, address ammStorage) {
//        require(ammTreasuryAddress != address(0), string.concat(IporErrors.WRONG_ADDRESS, " AMM treasury address cannot be 0"));
//        require(ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " AMM storage address cannot be 0"));

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
//                AmmTypes.Swap memory swap = ammStorage.getSwapPayFixed(swapId);
//                if (swap.state == uint256(IporTypes.SwapState.ACTIVE)) {
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
//                AmmTypes.Swap memory swap = _ammStorage.getSwapReceiveFixed(
//                    swapId
//                );
//                if (swap.state == uint256(IporTypes.SwapState.ACTIVE)) {
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
