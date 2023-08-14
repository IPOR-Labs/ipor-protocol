// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/StorageLib.sol";
import "../interfaces/IIpToken.sol";
import "../governance/AmmConfigurationManager.sol";
import "./IStETH.sol";
import "./IWETH9.sol";
import "./AmmLibEth.sol";
import "./IAmmPoolsServiceEth.sol";

contract AmmPoolsServiceEth is IAmmPoolsServiceEth {
    using IporContractValidator for address;
    using SafeERC20 for IStETH;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryEth;
    uint256 public immutable redeemFeeRateEth;
    address public immutable iporProtocolRouter;

    constructor(
        address stEthTemp,
        address wEthTemp,
        address ipstEthTemp,
        address ammTreasuryEthTemp,
        address iporProtocolRouterTemp,
        uint256 ethRedeemFeeRateTemp
    ) {
        stEth = stEthTemp.checkAddress();
        wEth = wEthTemp.checkAddress();
        ipstEth = ipstEthTemp.checkAddress();
        ammTreasuryEth = ammTreasuryEthTemp.checkAddress();
        iporProtocolRouter = iporProtocolRouterTemp.checkAddress();
        redeemFeeRateEth = ethRedeemFeeRateTemp;
    }

    modifier onlyRouter() {
        require(address(this) == iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function provideLiquidityStEth(address beneficiary, uint256 assetAmount) external payable override onlyRouter {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);

        uint256 newPoolBalance = assetAmount + IStETH(stEth).balanceOf(ammTreasuryEth);

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipstEth);

        IStETH(stEth).safeTransferFrom(msg.sender, ammTreasuryEth, assetAmount);

        uint256 ipTokenAmount = IporMath.division(assetAmount * 1e18, exchangeRate);
        IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

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

    function provideLiquidityWEth(address beneficiary, uint256 wEthAmount) external payable override onlyRouter {
        require(wEthAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);
        uint256 newPoolBalance = wEthAmount + IStETH(wEth).balanceOf(ammTreasuryEth);

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        IStETH(wEth).safeTransferFrom(msg.sender, address(this), wEthAmount);
        IWETH9(wEth).withdraw(wEthAmount);

        _depositEth(wEthAmount, beneficiary);
    }

    function provideLiquidityEth(address beneficiary, uint256 ethAmount) external payable onlyRouter {
        require(ethAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(msg.value > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);
        uint256 newPoolBalance = ethAmount + IStETH(stEth).balanceOf(ammTreasuryEth);
        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        _depositEth(ethAmount, beneficiary);
    }

    function redeemFromAmmPoolStEth(address beneficiary, uint256 ipTokenAmount) external onlyRouter {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipstEth).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipstEth);

        uint256 stEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);
        uint256 amountToRedeem = IporMath.division(stEthAmount * (1e18 - redeemFeeRateEth), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipstEth).burn(msg.sender, ipTokenAmount);

        IStETH(stEth).safeTransferFrom(ammTreasuryEth, beneficiary, amountToRedeem);

        emit RedeemStEth(
            block.timestamp,
            ammTreasuryEth,
            msg.sender,
            beneficiary,
            exchangeRate,
            ipTokenAmount,
            stEthAmount,
            amountToRedeem
        );
    }

    function _depositEth(uint256 ethAmount, address beneficiary) private {
        try IStETH(stEth).submit{value: ethAmount}(address(0)) {
            uint256 stEthAmount = IStETH(stEth).balanceOf(address(this));
            if (stEthAmount > 0) {
                uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipstEth);

                IStETH(stEth).safeTransfer(ammTreasuryEth, stEthAmount);

                uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);
                IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

                emit IAmmPoolsServiceEth.ProvideEthLiquidity(
                    block.timestamp,
                    msg.sender,
                    beneficiary,
                    ammTreasuryEth,
                    exchangeRate,
                    ethAmount,
                    stEthAmount,
                    ipTokenAmount
                );
            }
        } catch {
            revert IAmmPoolsServiceEth.StEthSubmitFailed({amount: ethAmount, errorCode: AmmErrors.STETH_SUBMIT_FAILED});
        }
    }
}
