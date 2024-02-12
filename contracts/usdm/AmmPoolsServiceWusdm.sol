// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IIpToken.sol";
import "../interfaces/types/AmmTypes.sol";
import "./interfaces/IAmmPoolsServiceWusdm.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/StorageLib.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceWusdm is IAmmPoolsServiceWusdm {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable wusdm;
    address public immutable ipWusdm;
    address public immutable ammTreasuryWusdm;
    address public immutable ammStorageWusdm;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRateWusdm;

    constructor(
        address wusdmInput,
        address ipWusdmInput,
        address ammTreasuryWusdmInput,
        address ammStorageWusdmInput,
        address iporOracleInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateWusdmInput
    ) {
        wusdm = wusdmInput.checkAddress();
        ipWusdm = ipWusdmInput.checkAddress();
        ammTreasuryWusdm = ammTreasuryWusdmInput.checkAddress();
        ammStorageWusdm = ammStorageWusdmInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        redeemFeeRateWusdm = redeemFeeRateWusdmInput;

        require(redeemFeeRateWusdmInput <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityWusdmToAmmPoolWusdm(address beneficiary, uint256 wusdmAmount) external payable override {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(wusdm);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWusdm).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + wusdmAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IERC20(wusdm).safeTransferFrom(msg.sender, ammTreasuryWusdm, wusdmAmount);

        uint256 ipTokenAmount = IporMath.division(wusdmAmount * 1e18, exchangeRate);

        IIpToken(ipWusdm).mint(beneficiary, ipTokenAmount);


        emit IAmmPoolsServiceWusdm.ProvideLiquidityWusdm(
            msg.sender,
            beneficiary,
            ammTreasuryWusdm,
            exchangeRate,
            wusdmAmount,
            ipTokenAmount
        );
    }

    function redeemFromAmmPoolWusdm(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipWusdm).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWusdm).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 wusdmAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.division(wusdmAmount * (1e18 - redeemFeeRateWusdm), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipWusdm).burn(msg.sender, ipTokenAmount);

        IERC20(wusdm).safeTransferFrom(ammTreasuryWusdm, beneficiary, amountToRedeem);

        emit RedeemWusdm(
            ammTreasuryWusdm,
            msg.sender,
            beneficiary,
            exchangeRate,
            wusdmAmount,
            amountToRedeem,
            ipTokenAmount
        );
    }


    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: wusdm,
            assetDecimals: 18,
            ipToken: ipWusdm,
            ammStorage: ammStorageWusdm,
            ammTreasury: ammTreasuryWusdm,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }
}
