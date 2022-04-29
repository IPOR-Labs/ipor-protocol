// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";

contract MockSpreadModel is IMiltonSpreadModel {
    uint256 _calculateQuotePayFixed;
    uint256 _calculateQuoteReceiveFixed;
    int256 _calculateSpreadPayFixed;
    int256 _calculateSpreadReceiveFixed;

    constructor(
        uint256 calculateQuotePayFixedValue,
        uint256 calculateQuoteReceiveFixedValue,
        int256 calculateSpreadPayFixedValue,
        int256 calculateSpreadReceiveFixedVaule
    ) {
        _calculateQuotePayFixed = calculateQuotePayFixedValue;
        _calculateQuoteReceiveFixed = calculateQuoteReceiveFixedValue;
        _calculateSpreadPayFixed = calculateSpreadPayFixedValue;
        _calculateSpreadReceiveFixed = calculateSpreadReceiveFixedVaule;
    }

    //@dev Quote = RefLeg + SpreadPremiums, RefLeg = max(IPOR, EMAi), Spread = RefLeg + SpreadPremiums - IPOR
    function calculateQuotePayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        return _calculateQuotePayFixed;
    }

    function setCalculateQuotePayFixed(uint256 value) external {
        _calculateQuotePayFixed = value;
    }

    //@dev Quote = RefLeg - SpreadPremiums, RefLeg = min(IPOR, EMAi), Spread = IPOR - RefLeg + SpreadPremiums
    function calculateQuoteReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        quoteValue = _calculateQuoteReceiveFixed;
    }

    function setCalculateQuoteReceiveFixed(uint256 value) external {
        _calculateQuoteReceiveFixed = value;
    }

    //@dev Spread = SpreadPremiums + RefLeg - IPOR
    function calculateSpreadPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPayFixed;
    }

    function setCalculateSpreadPayFixed(int256 value) external {
        _calculateSpreadPayFixed = value;
    }

    //@dev Spread = SpreadPremiums + IPOR - RefLeg
    function calculateSpreadReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        spreadValue = _calculateSpreadReceiveFixed;
    }

    function setCalculateSpreadReceiveFixed(int256 value) external {
        _calculateSpreadReceiveFixed = value;
    }
}
