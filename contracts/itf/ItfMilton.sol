// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../amm/v3/MiltonV3.sol";

abstract contract ItfMilton is MiltonV3 {
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

    function itfCloseSwapPayFixed(uint256 swapId, uint256 closeTimestamp) external {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        _transferLiquidationDepositAmount(_msgSender(), _closeSwapPayFixed(swap, closeTimestamp));
    }

    function itfCloseSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) external {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        _transferLiquidationDepositAmount(
            _msgSender(),
            _closeSwapReceiveFixed(swap, closeTimestamp)
        );
    }

    function itfCloseSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        (uint256 payoutForLiquidatorPayFixed, ) = _closeSwapsReceiveFixed(swapIds, closeTimestamp);
        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidatorPayFixed);
    }

    function itfCloseSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        (uint256 payoutForLiquidatorReceiveFixed, ) = _closeSwapsReceiveFixed(
            swapIds,
            closeTimestamp
        );

        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidatorReceiveFixed);
    }

    function itfCalculateSoap(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (soapPf, soapRf, soap) = _calculateSoap(calculateTimestamp);
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
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        return _calculatePayoffPayFixed(calculateTimestamp, swap);
    }

    function itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        return _calculatePayoffReceiveFixed(calculateTimestamp, swap);
    }

    function itfCalculateIncomeFeeValue(int256 payoff) external pure returns (uint256) {
        return _calculateIncomeFeeValue(payoff);
    }
}
