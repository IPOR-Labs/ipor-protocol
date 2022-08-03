// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadModel.sol";

contract MiltonSpreadModelDai is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return 44525308187;
    }

    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 7295029327499250688;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 1957606734120302592;
    }

    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return 2805894176280989;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 60862801283727532032;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 814944608049619968;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -155830648166213;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 21718204087089586176;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1067938568082170880;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -5807404091;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 12842479402900596736;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1078905683664530048;
    }
}
