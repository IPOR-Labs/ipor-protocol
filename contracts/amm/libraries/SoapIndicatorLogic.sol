// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/types/AmmStorageTypes.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../../libraries/math/InterestRates.sol";

library SoapIndicatorLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    function calculateSoapPayFixed(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            IporMath.division(si.totalIbtQuantity * ibtPrice, 1e18).toInt256() -
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256();
    }

    function calculateSoapReceiveFixed(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256() -
            IporMath.division(si.totalIbtQuantity * ibtPrice, 1e18).toInt256();
    }

    function calculateHyphoteticalInterestTotal(AmmStorageTypes.SoapIndicators memory si, uint256 calculateTimestamp)
        internal
        pure
        returns (uint256)
    {
        return
            si.hypotheticalInterestCumulative +
            calculateHypotheticalInterestDelta(
                calculateTimestamp,
                si.rebalanceTimestamp,
                si.totalNotional + si.hypotheticalInterestCumulative,
                si.averageInterestRate
            );
    }

    function calculateHypotheticalInterestDelta(
        uint256 calculateTimestamp,
        uint256 lastRebalanceTimestamp,
        uint256 totalNotional,
        uint256 averageInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= lastRebalanceTimestamp,
            AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP
        );
        return
            totalNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                averageInterestRate * (calculateTimestamp - lastRebalanceTimestamp)
            );
    }
}
