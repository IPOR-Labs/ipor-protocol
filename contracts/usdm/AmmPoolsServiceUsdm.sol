// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IIpToken.sol";
import "../interfaces/types/AmmTypes.sol";
import "./interfaces/IAmmPoolsServiceUsdm.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/StorageLib.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceUsdm is IAmmPoolsServiceUsdm {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable usdm;
    address public immutable ipUsdm;
    address public immutable ammTreasuryUsdm;
    address public immutable ammStorageUsdm;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRateUsdm;

    constructor(
        address usdmInput,
        address ipUsdmInput,
        address ammTreasuryUsdmInput,
        address ammStorageUsdmInput,
        address iporOracleInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateUsdmInput
    ) {
        usdm = usdmInput.checkAddress();
        ipUsdm = ipUsdmInput.checkAddress();
        ammTreasuryUsdm = ammTreasuryUsdmInput.checkAddress();
        ammStorageUsdm = ammStorageUsdmInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        redeemFeeRateUsdm = redeemFeeRateUsdmInput;

        require(redeemFeeRateUsdmInput <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityUsdmToAmmPoolUsdm(address beneficiary, uint256 usdmAmount) external payable override {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(usdm);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryUsdm).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + usdmAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IERC20(usdm).safeTransferFrom(msg.sender, ammTreasuryUsdm, usdmAmount);

        uint256 ipTokenAmount = IporMath.division(usdmAmount * 1e18, exchangeRate);

        IIpToken(ipUsdm).mint(beneficiary, ipTokenAmount);


        emit IAmmPoolsServiceUsdm.ProvideLiquidityUsdm(
            msg.sender,
            beneficiary,
            ammTreasuryUsdm,
            exchangeRate,
            usdmAmount,
            ipTokenAmount
        );
    }

    function redeemFromAmmPoolUsdm(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipUsdm).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryUsdm).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 wstEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.division(wstEthAmount * (1e18 - redeemFeeRateUsdm), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipUsdm).burn(msg.sender, ipTokenAmount);

        IERC20(usdm).safeTransferFrom(ammTreasuryUsdm, beneficiary, amountToRedeem);

        emit RedeemUsdm(
            ammTreasuryUsdm,
            msg.sender,
            beneficiary,
            exchangeRate,
            wstEthAmount,
            amountToRedeem,
            ipTokenAmount
        );
    }


    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: usdm,
            assetDecimals: 18,
            ipToken: ipUsdm,
            ammStorage: ammStorageUsdm,
            ammTreasury: ammTreasuryUsdm,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }
}
