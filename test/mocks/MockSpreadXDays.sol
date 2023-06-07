// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "../../contracts/interfaces/types/IporTypes.sol";

contract MockSpreadXDays {
    uint256 internal immutable _payFixedQuoteValue;
    uint256 internal immutable _receiveFixedQuoteValue;

    constructor(uint256 payFixedQuoteValue, uint256 receiveFixedQuoteValue) {
        _payFixedQuoteValue = payFixedQuoteValue;
        _receiveFixedQuoteValue = receiveFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRatePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRateReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRatePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRateReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRatePayFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateAndUpdateOfferedRateReceiveFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }
}
