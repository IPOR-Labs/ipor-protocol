// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../amm/spread/MiltonSpreadModelUsdc.sol";

contract ItfMiltonSpreadModelUsdc is MiltonSpreadModelUsdc {
    bool  internal _overrideParams;
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
    ) external {
        _overrideParams = true;
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
        if (_overrideParams) {
            return _payFixedRegionOneBase;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionOneBase();
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_overrideParams) {
            return _payFixedRegionOneSlopeForVolatility;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionOneSlopeForVolatility();
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view override returns (int256) {
        if (_overrideParams) {
            return _payFixedRegionOneSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionOneSlopeForMeanReversion();
    }

    function _getPayFixedRegionTwoBase() internal view override returns (int256) {
        if (_overrideParams) {
            return _payFixedRegionTwoBase;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionTwoBase();
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_overrideParams) {
            return _payFixedRegionTwoSlopeForVolatility;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionTwoSlopeForVolatility();
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view override returns (int256) {
        if (_overrideParams) {
            return _payFixedRegionTwoSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdc._getPayFixedRegionTwoSlopeForMeanReversion();
    }

    function _getReceiveFixedRegionOneBase() internal view override returns (int256) {
        if (_overrideParams) {
            return _receiveFixedRegionOneBase;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionOneBase();
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_overrideParams) {
            return _receiveFixedRegionOneSlopeForVolatility;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionOneSlopeForVolatility();
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        override
        returns (int256)
    {
        if (_overrideParams) {
            return _receiveFixedRegionOneSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionOneSlopeForMeanReversion();
    }

    function _getReceiveFixedRegionTwoBase() internal view override returns (int256) {
        if (_overrideParams) {
            return _receiveFixedRegionTwoBase;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionTwoBase();
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_overrideParams) {
            return _receiveFixedRegionTwoSlopeForVolatility;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionTwoSlopeForVolatility();
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        override
        returns (int256)
    {
        if (_overrideParams) {
            return _receiveFixedRegionTwoSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdc._getReceiveFixedRegionTwoSlopeForMeanReversion();
    }
}
