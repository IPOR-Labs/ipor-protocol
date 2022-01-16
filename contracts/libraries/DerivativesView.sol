// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { IporErrors } from "../IporErrors.sol";
import { Constants } from "../libraries/Constants.sol";

library DerivativesView {
    //@notice FOR FRONTEND
    //TODO: fix it, looks bad, DoS, possible out of gas
    function getPositions(DataTypes.MiltonDerivativesStorage storage miltonDerivatives)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        DataTypes.IporDerivativeMemory[]
            memory derivatives = new DataTypes.IporDerivativeMemory[](
                miltonDerivatives.ids.length
            );
        for (uint256 i = 0; i < miltonDerivatives.ids.length; i++) {
			uint256 id = miltonDerivatives.ids[i];
            derivatives[i] = 
			DataTypes.IporDerivativeMemory(
				uint256(miltonDerivatives.items[id].item.state),	
				miltonDerivatives.items[id].item.buyer,
				miltonDerivatives.items[id].item.asset,
				miltonDerivatives.items[id].item.startingTimestamp,
				miltonDerivatives.items[id].item.endingTimestamp,
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
        DataTypes.MiltonDerivativesStorage storage miltonDerivatives,
        address user
    ) external view returns (DataTypes.IporDerivativeMemory[] memory) {
        DataTypes.IporDerivativeMemory[]
            memory derivatives = new DataTypes.IporDerivativeMemory[](
                miltonDerivatives.userDerivativeIds[user].length
            );
        for (
            uint256 i = 0;
            i < miltonDerivatives.userDerivativeIds[user].length;
            i++
        ) {
			uint256 id = miltonDerivatives.userDerivativeIds[user][i];
            derivatives[i] = 
				DataTypes.IporDerivativeMemory(
					uint256(miltonDerivatives.items[id].item.state),
					miltonDerivatives.items[id].item.buyer,
					miltonDerivatives.items[id].item.asset,
					miltonDerivatives.items[id].item.startingTimestamp,
					miltonDerivatives.items[id].item.endingTimestamp,
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
