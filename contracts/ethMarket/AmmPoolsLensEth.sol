// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AmmLibEth.sol";
import "../libraries/IporContractValidator.sol";
import "./IAmmPoolsLensEth.sol";

contract AmmPoolsServiceEth is IAmmPoolsLensEth {
    using IporContractValidator for address;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ethIpToken;
    address public immutable ethAmmTreasury;
    uint256 public immutable ethRedeemFeeRate;

    constructor(
        address stEthTemp,
        address wEthTemp,
        address ethIpTokenTemp,
        address ethAmmTreasuryTemp,
        address iporProtocolRouterTemp,
        uint256 ethRedeemFeeRateTemp
    ) {
        stEth = stEthTemp.checkAddress();
        wEth = wEthTemp.checkAddress();
        ethIpToken = ethIpTokenTemp.checkAddress();
        ethAmmTreasury = ethAmmTreasuryTemp.checkAddress();
        ethRedeemFeeRate = ethRedeemFeeRateTemp;
    }



    function getExchangeRate() external view returns(uint256) {
        return AmmLibEth.getExchangeRate(stEth, ethAmmTreasury, ethIpToken);

    }

}
