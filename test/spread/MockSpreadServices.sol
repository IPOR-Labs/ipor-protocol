// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "contracts/amm/spread/ISpread28Days.sol";
import "contracts/amm/spread/ISpread60Days.sol";
import "contracts/amm/spread/ISpread90Days.sol";
import "contracts/amm/spread/ISpreadCloseSwapService.sol";
import "contracts/amm/spread/ISpread28DaysLens.sol";
import "contracts/amm/spread/ISpread60DaysLens.sol";
import "contracts/amm/spread/ISpread90DaysLens.sol";

contract MockSpreadServices is
    ISpread28Days,
    ISpread60Days,
    ISpread90Days,
    ISpreadCloseSwapService,
    ISpread28DaysLens,
    ISpread60DaysLens,
    ISpread90DaysLens
{
    function calculateAndUpdateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 280;
    }

    function calculateAndUpdateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 281;
    }

    function calculateAndUpdateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 600;
    }

    function calculateAndUpdateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 601;
    }

    function calculateAndUpdateOfferedRatePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 900;
    }

    function calculateAndUpdateOfferedRateReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 901;
    }

    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external override {
        return;
    }

    function calculateOfferedRatePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
    external
    override
    returns (uint256 quoteValue){
        return 280;}

    function calculateOfferedRateReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
    external
    override
    returns (uint256 quoteValue){
        return 281;
    }

    function spreadFunction28DaysConfig() external pure override returns (uint256[] memory){
        uint256[] memory mock = new uint256[](20);
        return mock;
    }

    function calculateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue){
        return 600;
    }

    function calculateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 601;
    }

    function spreadFunction60DaysConfig() external pure override returns (uint256[] memory){
        uint256[] memory mock = new uint256[](20);
        return mock;
    }

    function calculateOfferedRatePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue){
        return 900;
    }

    function calculateOfferedRateReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue){
        return 901;
    }

    function spreadFunction90DaysConfig() external pure override returns (uint256[] memory){
        uint256[] memory mock = new uint256[](20);
        return mock;
    }
}
