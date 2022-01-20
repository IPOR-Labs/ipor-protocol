// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { IporErrors } from "../IporErrors.sol";
import { Constants } from "../libraries/Constants.sol";
import { IMiltonStorage } from "../interfaces/IMiltonStorage.sol";

library DerivativesView {
    //@notice FOR FRONTEND
    //TODO: fix it, looks bad, DoS, possible out of gas
    function getPositions(IMiltonStorage.MiltonDerivativesStorage storage miltonDerivatives)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        DataTypes.IporDerivativeMemory[]
            memory derivatives = new DataTypes.IporDerivativeMemory[](
                miltonDerivatives.ids.length
            );
			uint256 i = 0;
        for (i; i != miltonDerivatives.ids.length; i++) {
			uint256 id = miltonDerivatives.ids[i];
            derivatives[i] = 
			DataTypes.IporDerivativeMemory(
				uint256(miltonDerivatives.items[id].item.state),	
				miltonDerivatives.items[id].item.buyer,
				miltonDerivatives.items[id].item.startingTimestamp,
				miltonDerivatives.items[id].item.startingTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
				miltonDerivatives.items[id].item.id,
				miltonDerivatives.items[id].item.collateral,
				miltonDerivatives.items[id].item.liquidationDepositAmount,
				miltonDerivatives.items[id].item.notionalAmount,
				miltonDerivatives.items[id].item.fixedInterestRate,
				miltonDerivatives.items[id].item.ibtQuantity
			);
			
        }
        return derivatives;
    }

    function getUserPositions(
        IMiltonStorage.MiltonDerivativesStorage storage miltonDerivatives,
        address user
    ) external view returns (DataTypes.IporDerivativeMemory[] memory) {
        DataTypes.IporDerivativeMemory[]
            memory derivatives = new DataTypes.IporDerivativeMemory[](
                miltonDerivatives.userDerivativeIds[user].length
            );
			uint256 i = 0;
        for (
            i;
            i != miltonDerivatives.userDerivativeIds[user].length;
            i++
        ) {
			uint256 id = miltonDerivatives.userDerivativeIds[user][i];
            derivatives[i] = 
				DataTypes.IporDerivativeMemory(
					uint256(miltonDerivatives.items[id].item.state),
					miltonDerivatives.items[id].item.buyer,
					miltonDerivatives.items[id].item.startingTimestamp,
					miltonDerivatives.items[id].item.startingTimestamp+ Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
					miltonDerivatives.items[id].item.id,
					miltonDerivatives.items[id].item.collateral,
					miltonDerivatives.items[id].item.liquidationDepositAmount,
					miltonDerivatives.items[id].item.notionalAmount,
					miltonDerivatives.items[id].item.fixedInterestRate,
					miltonDerivatives.items[id].item.ibtQuantity
				);			
        }
        return derivatives;
    }
}
