// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "./types/AmmMiltonStorageTypes.sol";
import "hardhat/console.sol";

library SoapIndicatorLogic {
    using SafeCast for uint256;

    function calculateQuasiSoapPayFixed(
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalIbtQuantity * ibtPrice * Constants.WAD_YEAR_IN_SECONDS).toInt256() -
            (si.totalNotional *
                Constants.WAD_P2_YEAR_IN_SECONDS +
                calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256();
    }

    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoapReceiveFixed(
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalNotional *
                Constants.WAD_P2_YEAR_IN_SECONDS +
                calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256() -
            (si.totalIbtQuantity * ibtPrice * Constants.WAD_YEAR_IN_SECONDS).toInt256();
    }

    function rebalanceWhenOpenSwap(
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal view returns (AmmMiltonStorageTypes.SoapIndicatorsMemory memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );
        uint256 quasiHypotheticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );
        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
        return si;
    }

    function rebalanceWhenCloseSwap(
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal view returns (AmmMiltonStorageTypes.SoapIndicatorsMemory memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        uint256 currentQuasiHypoteticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        uint256 quasiInterestPaidOut = calculateQuasiInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            swapFixedInterestRate
        );

        uint256 quasiHypotheticalInterestTotal;

        if (currentQuasiHypoteticalInterestTotal >= quasiInterestPaidOut) {
            quasiHypotheticalInterestTotal =
                currentQuasiHypoteticalInterestTotal -
                quasiInterestPaidOut;
        } else {
            quasiHypotheticalInterestTotal = 0;
        }

        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional - derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        console.log("[rebalanceWhenCloseSwap] averageInterestRate=", averageInterestRate);
        console.log(
            "[rebalanceWhenCloseSwap] quasiHypotheticalInterestTotal=",
            quasiHypotheticalInterestTotal
        );
        return si;
    }

    function calculateQuasiInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= derivativeOpenTimestamp,
            MiltonErrors.CALC_TIMESTAMP_HIGHER_THAN_SWAP_OPEN_TIMESTAMP
        );
        return
            derivativeNotional *
            swapFixedInterestRate *
            (calculateTimestamp - derivativeOpenTimestamp) *
            Constants.D18;
    }

    function calculateQuasiHyphoteticalInterestTotal(
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp
    ) internal pure returns (uint256) {
        return
            si.quasiHypotheticalInterestCumulative +
            calculateQuasiHypotheticalInterestDelta(
                calculateTimestamp,
                si.rebalanceTimestamp,
                si.totalNotional,
                si.averageInterestRate
            );
    }

    //division by Constants.YEAR_IN_SECONDS * 1e36 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(
        uint256 calculateTimestamp,
        uint256 lastRebalanceTimestamp,
        uint256 totalNotional,
        uint256 averageInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= lastRebalanceTimestamp,
            MiltonErrors.CALC_TIMESTAMP_LTHAN_SI_REBALANCE_TIMESTAMP
        );
        return
            totalNotional *
            averageInterestRate *
            ((calculateTimestamp - lastRebalanceTimestamp) * Constants.D18);
    }

    function calculateAverageInterestRateWhenOpenSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal view returns (uint256) {
        console.log(
            "[OPEN]CALC-ONE:",
            IporMath.division(
                (totalNotional * averageInterestRate + derivativeNotional * swapFixedInterestRate) *
                    1e9,
                (totalNotional + derivativeNotional)
            )
        );
        console.log(
            "[OPEN]CALC-TWO:",
            IporMath.division(
                (totalNotional * averageInterestRate + derivativeNotional * swapFixedInterestRate),
                (totalNotional + derivativeNotional)
            )
        );
        return
            IporMath.divisionWithoutRound(
                (totalNotional * averageInterestRate + derivativeNotional * swapFixedInterestRate),
                (totalNotional + derivativeNotional)
            );
    }

    function calculateAverageInterestRateWhenCloseSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal view returns (uint256) {
        require(
            derivativeNotional <= totalNotional,
            MiltonErrors.SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL
        );
        if (derivativeNotional == totalNotional) {
            return 0;
        } else {
            console.log(
                "[CLOSE]CALC-ONE:",
                IporMath.division(
                    (totalNotional *
                        averageInterestRate -
                        derivativeNotional *
                        swapFixedInterestRate) * 1e9,
                    (totalNotional - derivativeNotional)
                )
            );
            console.log(
                "[CLOSE]CALC-TWO:",
                IporMath.division(
                    (totalNotional *
                        averageInterestRate -
                        derivativeNotional *
                        swapFixedInterestRate),
                    (totalNotional - derivativeNotional)
                )
            );
            return
                IporMath.divisionWithoutRound(
                    (totalNotional *
                        averageInterestRate -
                        derivativeNotional *
                        swapFixedInterestRate),
                    (totalNotional - derivativeNotional)
                );
        }
    }
}
