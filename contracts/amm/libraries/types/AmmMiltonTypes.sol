// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../../interfaces/types/IporTypes.sol";

library AmmMiltonTypes {
    struct BeforeOpenSwapStruct {
        uint256 wadTotalAmount;
        uint256 collateral;
        uint256 notional;
        uint256 openingFeeLPValue;
        uint256 openingFeeTreasuryValue;
        uint256 iporPublicationFeeAmount;
        uint256 liquidationDepositAmount;
        IporTypes.AccruedIpor accruedIpor;
    }
}
