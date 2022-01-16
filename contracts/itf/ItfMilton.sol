// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../amm/Milton.sol";

contract ItfMilton is Milton {
    constructor(address initialIporConfiguration)
        Milton(initialIporConfiguration)
    {}

    function itfOpenSwapPayFixed(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external returns (uint256) {
        return
            _openSwapPayFixed(
                openTimestamp,
                asset,
                totalAmount,
                maximumSlippage,
                collateralizationFactor
            );
    }

	function itfOpenSwapReceiveFixed(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external returns (uint256) {
        return
            _openSwapReceiveFixed(
                openTimestamp,
                asset,
                totalAmount,
                maximumSlippage,
                collateralizationFactor
            );
    }

    function itfCloseSwapPayFixed(uint256 derivativeId, uint256 closeTimestamp)
        external
    {
        _closeSwapPayFixed(derivativeId, closeTimestamp);
    }

	function itfCloseSwapReceiveFixed(uint256 derivativeId, uint256 closeTimestamp)
        external
    {
        _closeSwapReceiveFixed(derivativeId, closeTimestamp);
    }

    function itfCalculateSoap(address asset, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (soapPf,soapRf, soap) = _calculateSoap(asset, calculateTimestamp);
    }

    function itfCalculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        (spreadPayFixedValue, spreadRecFixedValue) = _calculateSpread(
            asset,
            calculateTimestamp
        );
    }

    function itfCalculateSwapPayFixedValue(
        uint256 calculateTimestamp,
        DataTypes.IporDerivativeMemory memory derivative
    ) external view returns (int256) {
        return _calculateSwapPayFixedValue(calculateTimestamp, derivative);
    }

	function itfCalculateSwapReceiveFixedValue(
        uint256 calculateTimestamp,
        DataTypes.IporDerivativeMemory memory derivative
    ) external view returns (int256) {
        return _calculateSwapReceiveFixedValue(calculateTimestamp, derivative);
    }
}
