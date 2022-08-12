// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadModel.sol";

contract MiltonSpreadModelUsdc is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return 37930765449792;
    }

    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 31230683742008606720;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1000529805354521088;
    }

    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return 37489567944637;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 28996072243415703552;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1000994078840167424;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -122762757422490;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -106003266867109625856;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1045884298106898944;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -158867838624609;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -110594227975461961728;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 6710359117987209;
    }
}
