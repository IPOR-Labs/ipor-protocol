// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadModel.sol";

contract MiltonSpreadModelUsdc is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return -5798760680877324;
    }

    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 9125652139635976;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1029804083461314500;
    }

    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -116525510374192;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 2347231273478131;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1007124355450712000;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -8317313635911159;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 5566712981928809;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1046383320556341000;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -112303129788364;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -2980232791171467;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 1009057938869904100;
    }
}
