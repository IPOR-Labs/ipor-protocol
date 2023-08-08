// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AmmLibEth.sol";
import "../libraries/IporContractValidator.sol";
import "./IAmmPoolsLensEth.sol";

contract AmmPoolsLensEth is IAmmPoolsLensEth {
    using IporContractValidator for address;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipEth;
    address public immutable ammTreasuryEth;
    uint256 public immutable redeemFeeRateEth;

    constructor(
        address stEthTemp,
        address wEthTemp,
        address ipEthTemp,
        address ammTreasuryEthTemp,
        address iporProtocolRouterTemp,
        uint256 redeemFeeRateEthTemp
    ) {
        stEth = stEthTemp.checkAddress();
        wEth = wEthTemp.checkAddress();
        ipEth = ipEthTemp.checkAddress();
        ammTreasuryEth = ammTreasuryEthTemp.checkAddress();
        redeemFeeRateEth = redeemFeeRateEthTemp;
    }



    function getIpEthExchangeRate() external view returns(uint256) {
        return AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipEth);

    }

}
