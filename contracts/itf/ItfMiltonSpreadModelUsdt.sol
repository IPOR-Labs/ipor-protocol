// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../amm/spread/MiltonSpreadModelUsdt.sol";
import "hardhat/console.sol";

contract ItfMiltonSpreadModelUsdt is MiltonSpreadModelUsdt {
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
        console.logInt(receiveFixedRegionOneSlopeForMeanReversion);
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
        return MiltonSpreadModelUsdt._getPayFixedRegionOneBase();
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForVolatility != 0) {
            return _payFixedRegionOneSlopeForVolatility;
        }
        return MiltonSpreadModelUsdt._getPayFixedRegionOneSlopeForVolatility();
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionOneSlopeForMeanReversion != 0) {
            return _payFixedRegionOneSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdt._getPayFixedRegionOneSlopeForMeanReversion();
    }

    function _getPayFixedRegionTwoBase() internal view override returns (int256) {
        if (_payFixedRegionTwoBase != 0) {
            return _payFixedRegionTwoBase;
        }
        return MiltonSpreadModelUsdt._getPayFixedRegionTwoBase();
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForVolatility != 0) {
            return _payFixedRegionTwoSlopeForVolatility;
        }
        return MiltonSpreadModelUsdt._getPayFixedRegionTwoSlopeForVolatility();
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view override returns (int256) {
        if (_payFixedRegionTwoSlopeForMeanReversion != 0) {
            return _payFixedRegionTwoSlopeForMeanReversion;
        }
        return MiltonSpreadModelUsdt._getPayFixedRegionTwoSlopeForMeanReversion();
    }

    function _getReceiveFixedRegionOneBase() internal view override returns (int256) {
        if (_receiveFixedRegionOneBase != 0) {
            return _receiveFixedRegionOneBase;
        }
        return MiltonSpreadModelUsdt._getReceiveFixedRegionOneBase();
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionOneSlopeForVolatility != 0) {
            return _receiveFixedRegionOneSlopeForVolatility;
        }
        return MiltonSpreadModelUsdt._getReceiveFixedRegionOneSlopeForVolatility();
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
        return MiltonSpreadModelUsdt._getReceiveFixedRegionOneSlopeForMeanReversion();
    }

    function _getReceiveFixedRegionTwoBase() internal view override returns (int256) {
        if (_receiveFixedRegionTwoBase != 0) {
            return _receiveFixedRegionTwoBase;
        }
        return MiltonSpreadModelUsdt._getReceiveFixedRegionTwoBase();
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view override returns (int256) {
        if (_receiveFixedRegionTwoSlopeForVolatility != 0) {
            return _receiveFixedRegionTwoSlopeForVolatility;
        }
        return MiltonSpreadModelUsdt._getReceiveFixedRegionTwoSlopeForVolatility();
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
        return MiltonSpreadModelUsdt._getReceiveFixedRegionTwoSlopeForMeanReversion();
    }
}