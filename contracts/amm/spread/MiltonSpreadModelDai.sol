// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadModel.sol";

contract MiltonSpreadModelDai is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return -2714543751630169;
    }

    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 5778498209905531;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1002347321603598500;
    }

    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -25731295856915;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 1031070671223056;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1006206356742145000;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -2282614170747679;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -42067907929723001;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1002298460528469300;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -171041064911584;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -4206790792972301;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1004489212030199100;
    }
}
