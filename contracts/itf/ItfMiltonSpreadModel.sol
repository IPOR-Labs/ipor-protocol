// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

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
        return 1570169440701153;
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForVolatility != 0) {
            return _payFixedRegionOneSlopeForVolatility;
        }
        return 198788881093494850;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForMeanReversion != 0) {
            return _payFixedRegionOneSlopeForMeanReversion;
        }
        return -38331366057144010;
    }

    function _getPayFixedRegionTwoBase() internal view override returns (int256) {
        if (_payFixedRegionTwoBase != 0) {
            return _payFixedRegionTwoBase;
        }
        return 5957385912947852;
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForVolatility != 0) {
            return _payFixedRegionTwoSlopeForVolatility;
        }
        return 422085481190794900;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForMeanReversion != 0) {
            return _payFixedRegionTwoSlopeForMeanReversion;
        }
        return -1044585377149331200;
    }

    function _getReceiveFixedRegionOneBase() internal view override returns (int256) {
        if (_receiveFixedRegionOneBase != 0) {
            return _receiveFixedRegionOneBase;
        }
        return 237699618248428;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionOneSlopeForVolatility != 0) {
            return _receiveFixedRegionOneSlopeForVolatility;
        }
        return 35927957683456455;
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
        return 10158530403206013;
    }

    function _getReceiveFixedRegionTwoBase() internal view override returns (int256) {
        if (_receiveFixedRegionTwoBase != 0) {
            return _receiveFixedRegionTwoBase;
        }
        return -493406136001736;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionTwoSlopeForVolatility != 0) {
            return _receiveFixedRegionTwoSlopeForVolatility;
        }
        return -2696690872084165600;
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
        return -923865786926514900;
    }
}
