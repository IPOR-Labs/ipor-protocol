// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../contracts/interfaces/types/IporTypes.sol";

contract MockSpreadXDays {
    uint256 internal immutable _payFixedQuoteValue;
    uint256 internal immutable _receiveFixedQuoteValue;

    constructor(uint256 payFixedQuoteValue, uint256 receiveFixedQuoteValue) {
        _payFixedQuoteValue = payFixedQuoteValue;
        _receiveFixedQuoteValue = receiveFixedQuoteValue;
    }

    function calculateQuotePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateQuoteReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }

    function calculateQuotePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateQuoteReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }

    function calculateQuotePayFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _payFixedQuoteValue;
    }

    function calculateQuoteReceiveFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue)
    {
        return _receiveFixedQuoteValue;
    }
}
