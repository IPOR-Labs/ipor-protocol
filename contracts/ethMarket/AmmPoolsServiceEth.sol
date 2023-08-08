// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/AmmErrors.sol";
import "../interfaces/IIpToken.sol";
import "./IStETH.sol";
import "./AmmLibEth.sol";
import "./IAmmPoolsServiceEth.sol";
import "../libraries/StorageLib.sol";
import "../governance/AmmConfigurationManager.sol";


contract AmmPoolsServiceEth is IAmmPoolsServiceEth {
    using IporContractValidator for address;
    using SafeERC20 for IStETH;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipEth;
    address public immutable ammTreasuryEth;
    uint256 public immutable redeemFeeRateEth;
    address public immutable iporProtocolRouter;

    constructor(
        address stEthTemp,
        address wEthTemp,
        address ipEthTemp,
        address ammTreasuryEthTemp,
        address iporProtocolRouterTemp,
        uint256 ethRedeemFeeRateTemp
    ) {
        stEth = stEthTemp.checkAddress();
        wEth = wEthTemp.checkAddress();
        ipEth = ipEthTemp.checkAddress();
        ammTreasuryEth = ammTreasuryEthTemp.checkAddress();
        iporProtocolRouter = iporProtocolRouterTemp.checkAddress();
        redeemFeeRateEth = ethRedeemFeeRateTemp;
    }

    modifier onlyRouter() {
        require(address(this) == iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function provideLiquidityStEth(address beneficiary, uint256 assetAmount) external override onlyRouter {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            stEth
        );

        uint256 newPoolBalance = assetAmount + IStETH(stEth).balanceOf(ammTreasuryEth);

        require(newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18, AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH);

        uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipEth);

        IStETH(stEth).safeTransferFrom(msg.sender, ammTreasuryEth, assetAmount);

        uint256 ipTokenAmount = IporMath.division(assetAmount * 1e18, exchangeRate);
        IIpToken(ipEth).mint(beneficiary, ipTokenAmount);

        emit IAmmPoolsServiceEth.ProvideStEthLiquidity(
            block.timestamp,
            msg.sender,
            beneficiary,
            ammTreasuryEth,
            exchangeRate,
            assetAmount,
            ipTokenAmount
        );
    }

}
