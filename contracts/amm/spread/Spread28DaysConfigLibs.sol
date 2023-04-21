// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;


library Spread28DaysConfigLibs {

    struct BaseSpreadConfig {
        int256 payFixedRegionOneBase;
        int256 payFixedRegionOneSlopeForVolatility;
        int256 payFixedRegionOneSlopeForMeanReversion;
        int256 payFixedRegionTwoBase;
        int256 payFixedRegionTwoSlopeForVolatility;
        int256 payFixedRegionTwoSlopeForMeanReversion;
        int256 receiveFixedRegionOneBase;
        int256 receiveFixedRegionOneSlopeForVolatility;
        int256 receiveFixedRegionOneSlopeForMeanReversion;
        int256 receiveFixedRegionTwoBase;
        int256 receiveFixedRegionTwoSlopeForVolatility;
        int256 receiveFixedRegionTwoSlopeForMeanReversion;
    }

    function _getBaseSpreadDaiConfig() internal pure returns(BaseSpreadConfig memory){
        return BaseSpreadConfig({
            payFixedRegionOneBase: 310832623606789,
            payFixedRegionOneSlopeForVolatility: 5904923680478814208,
            payFixedRegionOneSlopeForMeanReversion: -1068281996426492416,
            payFixedRegionTwoBase: 250000000000000,
            payFixedRegionTwoSlopeForVolatility: 300000016093683515392,
            payFixedRegionTwoSlopeForMeanReversion: 0,
            receiveFixedRegionOneBase: -250000000214678,
            receiveFixedRegionOneSlopeForVolatility: -3289616086609,
            receiveFixedRegionOneSlopeForMeanReversion: 999999996306855424,
            receiveFixedRegionTwoBase: -250000000000000,
            receiveFixedRegionTwoSlopeForVolatility: -300000000394754064384,
            receiveFixedRegionTwoSlopeForMeanReversion: 0
        });
    }

    function _getBaseSpreadUsdcConfig() internal pure returns(BaseSpreadConfig memory){
        return BaseSpreadConfig({
            payFixedRegionOneBase: 246221635508210,
            payFixedRegionOneSlopeForVolatility: 7175545968273476608,
            payFixedRegionOneSlopeForMeanReversion: -998967008815501824,
            payFixedRegionTwoBase: 250000000000000,
            payFixedRegionTwoSlopeForVolatility: 600000002394766180352,
            payFixedRegionTwoSlopeForMeanReversion: 0,
            receiveFixedRegionOneBase: -250000000201288,
            receiveFixedRegionOneSlopeForVolatility: -2834673328995,
            receiveFixedRegionOneSlopeForMeanReversion: 999999997304907264,
            receiveFixedRegionTwoBase: -250000000000000,
            receiveFixedRegionTwoSlopeForVolatility: -600000000289261748224,
            receiveFixedRegionTwoSlopeForMeanReversion: 0
        });
    }

    function _getBaseSpreadUsdtConfig() internal pure returns(BaseSpreadConfig memory){
        return BaseSpreadConfig({
            payFixedRegionOneBase: 3663986060872150,
            payFixedRegionOneSlopeForVolatility: 51167356261242142720,
            payFixedRegionOneSlopeForMeanReversion: -1091077232860706176,
            payFixedRegionTwoBase: 250000000000000,
            payFixedRegionTwoSlopeForVolatility: 12500000093283319808,
            payFixedRegionTwoSlopeForMeanReversion: 0,
            receiveFixedRegionOneBase: -422356983119848,
            receiveFixedRegionOneSlopeForVolatility: -3072419563759,
            receiveFixedRegionOneSlopeForMeanReversion: -1037292358695855104,
            receiveFixedRegionTwoBase: -250000000000000,
            receiveFixedRegionTwoSlopeForVolatility: -12500447141509146624,
            receiveFixedRegionTwoSlopeForMeanReversion: 0
        });
    }





}