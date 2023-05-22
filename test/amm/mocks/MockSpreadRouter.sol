// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../../contracts/interfaces/types/IporTypes.sol";

contract MockSpreadRouter {
    uint256 internal _payFixed28DaysQuoteValue;
    uint256 internal _receiveFixed28DaysQuoteValue;

    constructor(uint256 payFixed28DaysQuoteValue, uint256 receiveFixed28DaysQuoteValue) {
        _payFixed28DaysQuoteValue = payFixed28DaysQuoteValue;
        _receiveFixed28DaysQuoteValue = receiveFixed28DaysQuoteValue;
    }

    function calculateQuotePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _payFixed28DaysQuoteValue;
    }

    function calculateQuoteReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        view
        returns (uint256 quoteValue)
    {
        return _receiveFixed28DaysQuoteValue;
    }
}
