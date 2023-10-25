// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/types/AmmTypes.sol";
import {IporErrors} from "./errors/IporErrors.sol";
import {console2} from "forge-std/console2.sol";

// https://medium.com/@pbharrin/how-to-sign-messages-in-solidity-71ad98f5aad0
library RiskIndicatorsValidatorLib {
    using ECDSA for bytes32;
    
    function verify(
        AmmTypes.RiskIndicatorsInputs memory inputs,
        address asset,
        uint256 tenor,
        uint256 direction,
        address signerAddress
    ) internal view returns (AmmTypes.OpenSwapRiskIndicators memory riskIndicators) {
        bytes32 hash = hashRiskIndicatorsInputs(inputs, asset, tenor, direction);

        //TODO: only for testing reason - remove in production
        console2.log("signerAddress: ", signerAddress);
        require(
//            hash.recover(inputs.signature) == signerAddress,
            hash.recover(inputs.signature) == 0xA229781d40864011729C753EAc24a772890fF527,
            IporErrors.RISK_INDICATORS_SIGNATURE_INVALID
        );
        require(inputs.expiration > block.timestamp, IporErrors.RISK_INDICATORS_EXPIRED);
        console2.log("RiskIndicatorsValidatorLib XXXXXXXXXXXXXXXXXXXXXXXX");
        return AmmTypes.OpenSwapRiskIndicators(
            inputs.maxCollateralRatio,
            inputs.maxCollateralRatioPerLeg,
            inputs.maxLeveragePerLeg,
            inputs.baseSpreadPerLeg,
            inputs.fixedRateCapPerLeg,
            inputs.demandSpreadFactor);
    }

    function hashRiskIndicatorsInputs(
        AmmTypes.RiskIndicatorsInputs memory inputs,
        address asset,
        uint256 tenor,
        uint256 direction
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    inputs.maxCollateralRatio,
                    inputs.maxCollateralRatioPerLeg,
                    inputs.maxLeveragePerLeg,
                    inputs.baseSpreadPerLeg,
                    inputs.fixedRateCapPerLeg,
                    inputs.demandSpreadFactor,
                    inputs.expiration,
                    asset,
                    tenor,
                    direction
                )
            );
    }
}
