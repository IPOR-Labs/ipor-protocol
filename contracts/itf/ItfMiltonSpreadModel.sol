// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "../amm/spread/MiltonSpreadModel.sol";

contract ItfMiltonSpreadModel is MiltonSpreadModel {
    int256 internal _payFixedRegionOneBase;
    int256 internal _payFixedRegionOneSlopeForVolatility;
    int256 internal _payFixedRegionOneSlopeForMeanReversion;

    int256 internal _payFixedRegionTwoBase;
    int256 internal _payFixedRegionTwoSlopeForVolatility;
    int256 internal _payFixedRegionTwoSlopeForMeanReversion;

    int256 internal _receiveFixedRegionOneBase;
    int256 internal _receiveFixedRegionOneSlopeForVolatility;
    int256 internal _receiveFixedRegionOneSlopeForMeanReversion;

    int256 internal _receiveFixedRegionTwoBase;
    int256 internal _receiveFixedRegionTwoSlopeForVolatility;
    int256 internal _receiveFixedRegionTwoSlopeForMeanReversion;

    function setupModelParams(
        int256 payFixedRegionOneBase,
        int256 payFixedRegionOneSlopeForVolatility,
        int256 payFixedRegionOneSlopeForMeanReversion,
        int256 payFixedRegionTwoBase,
        int256 payFixedRegionTwoSlopeForVolatility,
        int256 payFixedRegionTwoSlopeForMeanReversion,
        int256 receiveFixedRegionOneBase,
        int256 receiveFixedRegionOneSlopeForVolatility,
        int256 receiveFixedRegionOneSlopeForMeanReversion,
        int256 receiveFixedRegionTwoBase,
        int256 receiveFixedRegionTwoSlopeForVolatility,
        int256 receiveFixedRegionTwoSlopeForMeanReversion
    ) external onlyOwner {
        _payFixedRegionOneBase = payFixedRegionOneBase;
        _payFixedRegionOneSlopeForVolatility = payFixedRegionOneSlopeForVolatility;
        _payFixedRegionOneSlopeForMeanReversion = payFixedRegionOneSlopeForMeanReversion;
        _payFixedRegionTwoBase = payFixedRegionTwoBase;
        _payFixedRegionTwoSlopeForVolatility = payFixedRegionTwoSlopeForVolatility;
        _payFixedRegionTwoSlopeForMeanReversion = payFixedRegionTwoSlopeForMeanReversion;
        _receiveFixedRegionOneBase = receiveFixedRegionOneBase;
        _receiveFixedRegionOneSlopeForVolatility = receiveFixedRegionOneSlopeForVolatility;
        _receiveFixedRegionOneSlopeForMeanReversion = receiveFixedRegionOneSlopeForMeanReversion;
        _receiveFixedRegionTwoBase = receiveFixedRegionTwoBase;
        _receiveFixedRegionTwoSlopeForVolatility = receiveFixedRegionTwoSlopeForVolatility;
        _receiveFixedRegionTwoSlopeForMeanReversion = receiveFixedRegionTwoSlopeForMeanReversion;
    }

    function _getPayFixedRegionOneBase() internal view override returns (int256) {
        if (_payFixedRegionOneBase != 0) {
            return _payFixedRegionOneBase;
        }
        return _PAY_FIXED_REGION_ONE_BASE;
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForVolatility != 0) {
            return _payFixedRegionOneSlopeForVolatility;
        }
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForMeanReversion != 0) {
            return _payFixedRegionOneSlopeForMeanReversion;
        }
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getPayFixedRegionTwoBase() internal view override returns (int256) {
        if (_payFixedRegionTwoBase != 0) {
            return _payFixedRegionTwoBase;
        }
        return _PAY_FIXED_REGION_TWO_BASE;
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForVolatility != 0) {
            return _payFixedRegionTwoSlopeForVolatility;
        }
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForMeanReversion != 0) {
            return _payFixedRegionTwoSlopeForMeanReversion;
        }
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionOneBase() internal view override returns (int256) {
        if (_receiveFixedRegionOneBase != 0) {
            return _receiveFixedRegionOneBase;
        }
        return _RECEIVE_FIXED_REGION_ONE_BASE;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionOneSlopeForVolatility != 0) {
            return _receiveFixedRegionOneSlopeForVolatility;
        }
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        override
        returns (int256)
    {
        if (_receiveFixedRegionOneSlopeForMeanReversion != 0) {
            return _receiveFixedRegionOneSlopeForMeanReversion;
        }
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionTwoBase() internal view override returns (int256) {
        if (_receiveFixedRegionTwoBase != 0) {
            return _receiveFixedRegionTwoBase;
        }
        return _RECEIVE_FIXED_REGION_TWO_BASE;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionTwoSlopeForVolatility != 0) {
            return _receiveFixedRegionTwoSlopeForVolatility;
        }
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        override
        returns (int256)
    {
        if (_receiveFixedRegionTwoSlopeForMeanReversion != 0) {
            return _receiveFixedRegionTwoSlopeForMeanReversion;
        }
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }
}
