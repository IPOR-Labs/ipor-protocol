// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadModel.sol";

contract MiltonSpreadModelDai is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return 223452028860278;
    }

    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 66176612458519781376;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1186134254033851648;
    }

    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return 145660962344800;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 213838820626510938112;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -963243845920214784;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -86557160865515;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -37390455427043344384;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1129730689647621632;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -55994330424481;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -89741154814986338304;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 37480678662666200;
    }
}
