// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "../amm/Milton.sol";

abstract contract ItfMilton is Milton {
    using SafeCast for uint256;

    function itfOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256) {
        return _openSwapPayFixed(openTimestamp, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function itfOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256) {
        return
            _openSwapReceiveFixed(
                openTimestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            );
    }

    function itfCloseSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        uint256 closeTimestamp
    )
        external
        nonReentrant
        whenNotPaused
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            closeTimestamp
        );
    }

    function itfCloseSwapPayFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, closeTimestamp);
    }

    function itfCloseSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, closeTimestamp);
    }

    function itfCloseSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(swapIds, closeTimestamp);
    }

    function itfCloseSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
            swapIds,
            closeTimestamp
        );
    }

    function itfCalculateSoap(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (soapPayFixed, soapReceiveFixed, soap) = _calculateSoap(calculateTimestamp);
    }

    function itfCalculateSpread(uint256 calculateTimestamp)
        external
        view
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        (spreadPayFixed, spreadReceiveFixed) = _calculateSpread(calculateTimestamp);
    }

    function itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        return _itfCalculateSwapPayFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        return _itfCalculateSwapReceiveFixedValue(calculateTimestamp, swapId);
    }

    function itfCalculateIncomeFeeValue(int256 payoff) external pure returns (uint256) {
        return _calculateIncomeFeeValue(payoff);
    }

    function itfCalculatePnlForSwaps(
        uint256 calculateTimestamp,
        uint256[] memory swapIdsPayFixed,
        uint256[] memory swapIdsReceiveFixed
    ) external view returns (int256 plnValue, int256 payoffGross) {
        for (uint256 i = 0; i != swapIdsPayFixed.length; i++) {
            int256 payoff = _itfCalculateSwapPayFixedValue(calculateTimestamp, swapIdsPayFixed[i]);
            payoffGross += payoff;
            plnValue += _itfSubstractIncomeFeeValue(payoff);
        }
        for (uint256 j = 0; j != swapIdsReceiveFixed.length; j++) {
            int256 payoff = _itfCalculateSwapReceiveFixedValue(
                calculateTimestamp,
                swapIdsReceiveFixed[j]
            );
            payoffGross += payoff;
            plnValue += _itfSubstractIncomeFeeValue(payoff);
        }
    }

    function _itfSubstractIncomeFeeValue(int256 payoff) internal pure returns (int256) {
        if (payoff <= 0) {
            return payoff;
        }
        return payoff - _calculateIncomeFeeValue(payoff).toInt256();
    }

    function _itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        return _calculatePayoffPayFixed(calculateTimestamp, swap);
    }

    function _itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        internal
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        return _calculatePayoffReceiveFixed(calculateTimestamp, swap);
    }
}
