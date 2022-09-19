// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "hardhat/console.sol";
import "../interfaces/IMiltonStorage.sol";
import "./types/ItfMiltonTypes.sol";
import "./ItfMilton.sol";
import "../libraries/errors/MiltonErrors.sol";

contract ItfLiquidator {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    ItfMilton private _milton;
    IMiltonStorage private _miltonStorage;
    uint256 private constant _LIQUIDATION_LEG_LIMIT = 10;

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

        require(
            payFixedSwapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );
        require(
            receiveFixedSwapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );
        if (payFixedSwapIds.length > 0) {
            payFixedClosedSwaps = new MiltonTypes.IporSwapClosingResult[](payFixedSwapIds.length);
            for (uint256 i = 0; i < payFixedSwapIds.length; i++) {
                uint256 swapId = payFixedSwapIds[i];
                IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapPayFixed(swapId);
                if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                    try _milton.itfCloseSwapPayFixed(swapId, closeTimestamp) {
                        console.log("Successful close swap pay fixed");
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
                    } catch {
                        console.log("Unsuccessful close swap pay fixed (catch)");
                        payFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                    }
                } else {
                    console.log("ERR: Close swap pay fixed failed");
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
                        console.log("Successful close swap receive fixed");
                        receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(
                            swapId,
                            true
                        );
                    } catch {
                        console.log("Unsuccessful close swap receive fixed (catch)");
                        receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(
                            swapId,
                            false
                        );
                    }
                } else {
                    console.log("ERR: Close swap receive fixed failed");
                    receiveFixedClosedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
                }
            }
        }
    }

    function _getMiltonStorage() internal view virtual returns (IMiltonStorage) {
        return _miltonStorage;
    }

    function _getLiquidationLegLimit() internal view virtual returns (uint256) {
        return _LIQUIDATION_LEG_LIMIT;
    }

}
