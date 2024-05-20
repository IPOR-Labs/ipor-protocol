// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/StorageLib.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";
import {IAmmPoolsServiceUsdc} from "../interfaces/IAmmPoolsServiceUsdc.sol";


/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceUsdc is IAmmPoolsServiceUsdc {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable asset;
    uint256 public immutable assetDecimals;
    address public immutable ipToken;
    address public immutable ammTreasury;
    address public immutable ammStorage;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRate;

    constructor(
        address assetInput,
        address ipTokenInput,
        address ammTreasuryInput,
        address ammStorageInput,
        address iporOracleInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateInput
    ) {
        asset = assetInput.checkAddress();
        assetDecimals = IERC20Metadata(asset).decimals();
        ipToken = ipTokenInput.checkAddress();
        ammTreasury = ammTreasuryInput.checkAddress();
        ammStorage = ammStorageInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        redeemFeeRate = redeemFeeRateInput;

        require(redeemFeeRateInput <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityUsdcToAmmPoolUsdc(address beneficiary, uint256 assetAmount) external payable override {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(asset);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance();

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, assetDecimals);

        uint256 newPoolBalance = actualLiquidityPoolBalance + wadAssetAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IERC20(asset).safeTransferFrom(msg.sender, ammTreasury, assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * 1e18, exchangeRate);

        IIpToken(ipToken).mint(beneficiary, ipTokenAmount);

        emit ProvideLiquidity(
            asset,
            msg.sender,
            beneficiary,
            ammTreasury,
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount
        );
    }

    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipToken).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.convertWadToAssetDecimals(
            IporMath.division(wadAssetAmount * (1e18 - redeemFeeRate), 1e18), assetDecimals);

        uint256 wadAmountToRedeem = IporMath.convertToWad(amountToRedeem, assetDecimals);

        require(amountToRedeem > 0 && wadAmountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipToken).burn(msg.sender, ipTokenAmount);

        IERC20(asset).safeTransferFrom(ammTreasury, beneficiary, amountToRedeem);

        emit Redeem(
            asset,
            ammTreasury,
            msg.sender,
            beneficiary,
            exchangeRate,
            wadAssetAmount,
            wadAmountToRedeem,
            ipTokenAmount
        );
    }


    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: asset,
            assetDecimals: 18,
            ipToken: ipToken,
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }
}
