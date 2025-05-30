// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/math/IporMath.sol";

import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../libraries/ProvideLiquidityEvents.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../../../amm-weEth/interfaces/IAmmPoolsServiceWeEth.sol";
import "../../../amm-weEth/interfaces/IWeEth.sol";
import "../../../amm-weEth/interfaces/IWETH.sol";
import "../../../amm-weEth/interfaces/IEEthLiquidityPool.sol";
import "../../../base/libraries/StorageLibBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceWeEth is IAmmPoolsServiceWeEth {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable eth;
    address public immutable wEth;
    address public immutable eEth;
    address public immutable weEth;
    address public immutable ipWeEth;
    address public immutable eEthLiquidityPoolExternal; // NOT IporPool address from mainnet 0x308861A430be4cce5502d0A12724771Fc6DaF216
    address public immutable ammTreasuryWeEth;
    address public immutable ammStorageWeEth;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRateWeEth;
    address public immutable referral; // 0x558c8eb91F6fd83FC5C995572c3515E2DAF7b7e0 ???

    struct DeployedContracts {
        address ethInput;
        address wEthInput;
        address eEthInput;
        address weEthInput;
        address ipWeEthInput;
        address ammTreasuryWeEthInput;
        address ammStorageWeEthInput;
        address iporOracleInput;
        address iporProtocolRouterInput;
        uint256 redeemFeeRateWeEthInput;
        address eEthLiquidityPoolExternalInput;
        address referralInput;
    }

    constructor(DeployedContracts memory deployedContracts) {
        eth = deployedContracts.ethInput.checkAddress();
        wEth = deployedContracts.wEthInput.checkAddress();
        eEth = deployedContracts.eEthInput.checkAddress();
        weEth = deployedContracts.weEthInput.checkAddress();
        ipWeEth = deployedContracts.ipWeEthInput.checkAddress();
        ammTreasuryWeEth = deployedContracts.ammTreasuryWeEthInput.checkAddress();
        ammStorageWeEth = deployedContracts.ammStorageWeEthInput.checkAddress();
        iporOracle = deployedContracts.iporOracleInput.checkAddress();
        iporProtocolRouter = deployedContracts.iporProtocolRouterInput.checkAddress();
        eEthLiquidityPoolExternal = deployedContracts.eEthLiquidityPoolExternalInput.checkAddress();
        redeemFeeRateWeEth = deployedContracts.redeemFeeRateWeEthInput;
        referral = deployedContracts.referralInput.checkAddress();

        require(redeemFeeRateWeEth <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidity(
        address poolAsset,
        address inputAsset,
        address beneficiary,
        uint256 inputAssetAmount
    ) external payable override returns (uint256 ipTokenAmount) {
        if (inputAssetAmount == 0) {
            revert IporErrors.WrongAmount(IporErrors.VALUE_NOT_GREATER_THAN_ZERO, inputAssetAmount);
        }

        if (poolAsset == weEth && inputAsset == weEth) {
            return _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, inputAssetAmount, msg.sender);
        }

        if (poolAsset == weEth && inputAsset == eEth) {
            uint256 weEthAmount = _wrapEethToWeEth(inputAssetAmount, msg.sender);
            return _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, weEthAmount, iporProtocolRouter);
        }

        if (poolAsset == weEth && inputAsset == eth) {
            if (msg.value != inputAssetAmount) {
                revert IporErrors.WrongAmount(IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER, msg.value);
            }

            uint256 eEthAmount = _depositEthToEethLiquidityPoolExternal(inputAssetAmount);
            uint256 weEthAmount = _wrapEethToWeEth(eEthAmount, iporProtocolRouter);
            return _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, weEthAmount, iporProtocolRouter);
        }

        if (poolAsset == weEth && inputAsset == wEth) {
            _unwrapWethToEth(inputAssetAmount);
            uint256 eEthAmount = _depositEthToEethLiquidityPoolExternal(inputAssetAmount);
            uint256 weEthAmount = _wrapEethToWeEth(eEthAmount, iporProtocolRouter);
            return _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, weEthAmount, iporProtocolRouter);
        }
        revert IporErrors.UnsupportedAssetPair(IporErrors.ASSET_NOT_SUPPORTED, poolAsset, inputAsset);
    }

    function provideLiquidityWeEthToAmmPoolWeEth(address beneficiary, uint256 weEthAmount) external override {
        _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, weEthAmount, msg.sender);
    }

    function redeemFromAmmPoolWeEth(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipWeEth).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWeEth).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 weEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.division(weEthAmount * (1e18 - redeemFeeRateWeEth), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipWeEth).burn(msg.sender, ipTokenAmount);

        IERC20(weEth).safeTransferFrom(ammTreasuryWeEth, beneficiary, amountToRedeem);

        emit ProvideLiquidityEvents.Redeem(
            weEth,
            ammTreasuryWeEth,
            msg.sender,
            beneficiary,
            exchangeRate,
            weEthAmount,
            amountToRedeem,
            ipTokenAmount
        );
    }

    function _unwrapWethToEth(uint256 wEthAmount) internal {
        IWETH(wEth).safeTransferFrom(msg.sender, iporProtocolRouter, wEthAmount);
        IWETH(wEth).withdraw(wEthAmount);
    }

    function _depositEthToEethLiquidityPoolExternal(uint256 ethAmount) internal returns (uint256 eEthAmount) {
        IEEthLiquidityPool(eEthLiquidityPoolExternal).deposit{value: ethAmount}(referral);
        eEthAmount = IEEthLiquidityPool(eEthLiquidityPoolExternal).getTotalEtherClaimOf(iporProtocolRouter);
        if (eEthAmount == 0) {
            revert IporErrors.WrongAmount(IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER, eEthAmount);
        }
    }

    function _wrapEethToWeEth(uint256 inputAssetAmount, address eEthFrom) internal returns (uint256 weEthAmount) {
        if (eEthFrom != iporProtocolRouter) {
            IERC20(eEth).safeTransferFrom(eEthFrom, iporProtocolRouter, inputAssetAmount);
        }
        IERC20(eEth).approve(weEth, inputAssetAmount);
        weEthAmount = IWeEth(weEth).wrap(inputAssetAmount);

        if (weEthAmount == 0) {
            revert IporErrors.WrongAmount(IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER, weEthAmount);
        }
    }

    function _provideLiquidityWeEthToAmmPoolWeEth(
        address beneficiary,
        uint256 weEthAmount,
        address weEthFrom
    ) internal returns (uint256 ipTokenAmount) {
        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(weEth);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWeEth).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + weEthAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        if (weEthFrom != iporProtocolRouter) {
            IERC20(weEth).safeTransferFrom(weEthFrom, ammTreasuryWeEth, weEthAmount);
        } else {
            IERC20(weEth).safeTransfer(ammTreasuryWeEth, weEthAmount);
        }
        ipTokenAmount = IporMath.division(weEthAmount * 1e18, exchangeRate);

        IIpToken(ipWeEth).mint(beneficiary, ipTokenAmount);

        emit ProvideLiquidityEvents.ProvideLiquidity(
            weEth,
            msg.sender,
            beneficiary,
            ammTreasuryWeEth,
            exchangeRate,
            weEthAmount,
            ipTokenAmount
        );
    }

    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: weEth,
            assetDecimals: 18,
            ipToken: ipWeEth,
            ammStorage: ammStorageWeEth,
            ammTreasury: ammTreasuryWeEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }
}
