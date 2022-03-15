// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../amm/Milton.sol";

abstract contract ItfMilton is Milton {
    function itfOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) external returns (uint256) {
        return
            _openSwapPayFixed(
                openTimestamp,
                totalAmount,
                toleratedQuoteValue,
                collateralizationFactor
            );
    }

    function itfOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) external returns (uint256) {
        return
            _openSwapReceiveFixed(
                openTimestamp,
                totalAmount,
                toleratedQuoteValue,
                collateralizationFactor
            );
    }

    function itfCloseSwapPayFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapPayFixed(swapId, closeTimestamp);
    }

    function itfCloseSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) external {
        _closeSwapReceiveFixed(swapId, closeTimestamp);
    }

    function itfCloseSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        _closeSwapsPayFixed(swapIds, closeTimestamp);
    }

    function itfCloseSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) external {
        _closeSwapsReceiveFixed(swapIds, closeTimestamp);
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
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        (spreadPayFixedValue, spreadRecFixedValue) = _calculateSpread(calculateTimestamp);
    }

    function itfCalculateSwapPayFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapPayFixed(swapId);
        return _calculateSwapPayFixedValue(calculateTimestamp, swap);
    }

    function itfCalculateSwapReceiveFixedValue(uint256 calculateTimestamp, uint256 swapId)
        external
        view
        returns (int256)
    {
        IporTypes.IporSwapMemory memory swap = _miltonStorage.getSwapReceiveFixed(swapId);
        return _calculateSwapReceiveFixedValue(calculateTimestamp, swap);
    }

    function itfCalculateIncomeFeeValue(int256 positionValue) external pure returns (uint256) {
        return _calculateIncomeFeeValue(positionValue);
    }
}
