// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../interfaces/IAmmPoolsServiceWstEthBaseV1.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/StorageLib.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Asset Management is NOT supported in this contract. Rebalancing between AMM Treasury and Asset Management is NOT supported in this contract.
contract AmmPoolsServiceWstEthBaseV1 is IAmmPoolsServiceWstEthBaseV1 {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable wstEth;
    address public immutable ipwstEth;
    address public immutable ammTreasuryWstEth;
    address public immutable ammStorageWstEth;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRateWstEth;

    constructor(
        address wstEth_,
        address ipwstEth_,
        address ammTreasuryWstEth_,
        address ammStorageWstEth_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRateWstEth_
    ) {
        wstEth = wstEth_.checkAddress();
        ipwstEth = ipwstEth_.checkAddress();
        ammTreasuryWstEth = ammTreasuryWstEth_.checkAddress();
        ammStorageWstEth = ammStorageWstEth_.checkAddress();
        iporOracle = iporOracle_.checkAddress();
        iporProtocolRouter = iporProtocolRouter_.checkAddress();
        redeemFeeRateWstEth = redeemFeeRateWstEth_;

        require(redeemFeeRateWstEth_ <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityWstEth(address beneficiary, uint256 wstEthAmount) external payable override {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(wstEth);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWstEth).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + wstEthAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IERC20(wstEth).safeTransferFrom(msg.sender, ammTreasuryWstEth, wstEthAmount);

        uint256 ipTokenAmount = IporMath.division(wstEthAmount * 1e18, exchangeRate);

        IIpToken(ipwstEth).mint(beneficiary, ipTokenAmount);

        emit IAmmPoolsServiceWstEthBaseV1.ProvideLiquidityWstEth(
            msg.sender,
            beneficiary,
            ammTreasuryWstEth,
            exchangeRate,
            wstEthAmount,
            ipTokenAmount
        );
    }

    function redeemFromAmmPoolWstEth(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipwstEth).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWstEth).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 wstEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.division(wstEthAmount * (1e18 - redeemFeeRateWstEth), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipwstEth).burn(msg.sender, ipTokenAmount);

        IERC20(wstEth).safeTransferFrom(ammTreasuryWstEth, beneficiary, amountToRedeem);

        emit IAmmPoolsServiceWstEthBaseV1.RedeemWstEth(
            ammTreasuryWstEth,
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
            asset: wstEth,
            assetDecimals: 18,
            ipToken: ipwstEth,
            ammStorage: ammStorageWstEth,
            ammTreasury: ammTreasuryWstEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }
}
