// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/StorageLib.sol";
import "../interfaces/IIpToken.sol";
import "../governance/AmmConfigurationManager.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IAmmPoolsServiceEth.sol";
import "./AmmLibEth.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceEth is IAmmPoolsServiceEth {
    using IporContractValidator for address;
    using SafeERC20 for IStETH;
    using SafeERC20 for IWETH9;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryEth;
    uint256 public immutable redeemFeeRateStEth;
    address public immutable iporProtocolRouter;

    constructor(
        address stEthInput,
        address wEthInput,
        address ipstEthInput,
        address ammTreasuryEthInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateStEthInput
    ) {
        stEth = stEthInput.checkAddress();
        wEth = wEthInput.checkAddress();
        ipstEth = ipstEthInput.checkAddress();
        ammTreasuryEth = ammTreasuryEthInput.checkAddress();
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        redeemFeeRateStEth = redeemFeeRateStEthInput;

        require(redeemFeeRateStEthInput <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityStEth(address beneficiary, uint256 stEthAmount) external payable override {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);

        uint256 newPoolBalance = stEthAmount + IStETH(stEth).balanceOf(ammTreasuryEth);

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ipstEth, ammTreasuryEth);

        IStETH(stEth).safeTransferFrom(msg.sender, ammTreasuryEth, stEthAmount);

        uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);

        IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

        emit IAmmPoolsServiceEth.ProvideLiquidityStEth(
            msg.sender,
            beneficiary,
            ammTreasuryEth,
            exchangeRate,
            stEthAmount,
            ipTokenAmount
        );
    }

    function provideLiquidityWEth(address beneficiary, uint256 wEthAmount) external payable override {
        require(wEthAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);
        uint256 newPoolBalance = wEthAmount + IStETH(stEth).balanceOf(ammTreasuryEth);

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        IWETH9(wEth).safeTransferFrom(msg.sender, iporProtocolRouter, wEthAmount);
        IWETH9(wEth).withdraw(wEthAmount);

        _depositEth(wEthAmount, beneficiary);
    }

    function provideLiquidityEth(address beneficiary, uint256 ethAmount) external payable {
        require(ethAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(msg.value > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(stEth);
        uint256 newPoolBalance = ethAmount + IStETH(stEth).balanceOf(ammTreasuryEth);
        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        _depositEth(ethAmount, beneficiary);
    }

    function redeemFromAmmPoolStEth(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipstEth).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ipstEth, ammTreasuryEth);

        uint256 stEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);
        uint256 amountToRedeem = IporMath.division(stEthAmount * (1e18 - redeemFeeRateStEth), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipstEth).burn(msg.sender, ipTokenAmount);

        IStETH(stEth).safeTransferFrom(ammTreasuryEth, beneficiary, amountToRedeem);

        emit RedeemStEth(
            ammTreasuryEth,
            msg.sender,
            beneficiary,
            exchangeRate,
            stEthAmount,
            amountToRedeem,
            ipTokenAmount
        );
    }

    function _depositEth(uint256 ethAmount, address beneficiary) private {
        try IStETH(stEth).submit{value: ethAmount}(address(0)) {
            uint256 stEthAmount = IStETH(stEth).balanceOf(address(this));

            if (stEthAmount > 0) {
                uint256 exchangeRate = AmmLibEth.getExchangeRate(stEth, ipstEth, ammTreasuryEth);

                IStETH(stEth).safeTransfer(ammTreasuryEth, stEthAmount);

                uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);

                IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

                emit IAmmPoolsServiceEth.ProvideLiquidityEth(
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
