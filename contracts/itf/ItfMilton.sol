// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../amm/Milton.sol";

abstract contract ItfMilton is Milton {
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
        _transferLiquidationDepositAmount(_msgSender(), _closeSwapPayFixed(swapId, closeTimestamp));
    }

    function itfCloseSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) external {
        _transferLiquidationDepositAmount(
            _msgSender(),
            _closeSwapReceiveFixed(swapId, closeTimestamp)
        );
    }

    function itfCloseSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        _transferLiquidationDepositAmount(_msgSender(), _closeSwapsPayFixed(swapIds, closeTimestamp));
    }

    function itfCloseSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        _transferLiquidationDepositAmount(
            _msgSender(),
            _closeSwapsReceiveFixed(swapIds, closeTimestamp)
        );
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
