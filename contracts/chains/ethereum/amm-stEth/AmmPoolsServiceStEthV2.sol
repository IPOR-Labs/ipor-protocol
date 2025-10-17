// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../amm-eth/interfaces/IStETH.sol";
import "../../../amm-eth/interfaces/IWETH9.sol";
import "../../../amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV2.sol";
import "../../../base/amm/services/AmmPoolsServiceBaseV1.sol";

/// @title AMM Pools Service for stETH with Asset Management (V2)
/// @notice Supports providing liquidity with stETH, ETH, and WETH
/// @notice Includes auto-rebalancing between AMM Treasury and Asset Management (Plasma Vault)
/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceStEthV2 is IAmmPoolsServiceStEth, AmmPoolsServiceBaseV1 {
    using IporContractValidator for address;
    using SafeERC20 for IStETH;
    using SafeERC20 for IWETH9;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable ST_ETH;
    address public immutable W_ETH;

    constructor(
        address stEth_,
        address wEth_,
        address ipToken_,
        address ammTreasury_,
        address ammStorage_,
        address ammAssetManagement_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRate_,
        uint256 autoRebalanceThresholdMultiplier_
    )
        AmmPoolsServiceBaseV1(
            stEth_,
            ipToken_,
            ammTreasury_,
            ammStorage_,
            ammAssetManagement_,
            iporOracle_,
            iporProtocolRouter_,
            redeemFeeRate_,
            autoRebalanceThresholdMultiplier_
        )
    {
        ST_ETH = stEth_.checkAddress();
        W_ETH = wEth_.checkAddress();
    }

    /// @notice Provides liquidity to the AMM pool using stETH tokens
    /// @param beneficiary Address that will receive ipstETH tokens
    /// @param stEthAmount Amount of stETH to deposit (in 18 decimals)
    function provideLiquidityStEth(address beneficiary, uint256 stEthAmount) external payable override {
        _provideLiquidity(beneficiary, stEthAmount);
    }

    /// @notice Provides liquidity to the AMM pool using WETH tokens
    /// @dev WETH is unwrapped to ETH and then converted to stETH via Lido
    /// @param beneficiary Address that will receive ipstETH tokens
    /// @param wEthAmount Amount of WETH to deposit (in 18 decimals)
    function provideLiquidityWEth(address beneficiary, uint256 wEthAmount) external payable override {
        require(wEthAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            asset
        );

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV2(ammTreasury).getLiquidityPoolBalance();
        uint256 newPoolBalance = wEthAmount + actualLiquidityPoolBalance;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        IWETH9(W_ETH).safeTransferFrom(msg.sender, iporProtocolRouter, wEthAmount);
        IWETH9(W_ETH).withdraw(wEthAmount);

        _depositEth(wEthAmount, beneficiary, actualLiquidityPoolBalance);
    }

    /// @notice Provides liquidity to the AMM pool using ETH
    /// @dev ETH is converted to stETH via Lido
    /// @param beneficiary Address that will receive ipstETH tokens
    /// @param ethAmount Amount of ETH to deposit (in 18 decimals)
    function provideLiquidityEth(address beneficiary, uint256 ethAmount) external payable override {
        require(ethAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(msg.value > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            asset
        );

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV2(ammTreasury).getLiquidityPoolBalance();
        uint256 newPoolBalance = ethAmount + actualLiquidityPoolBalance;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        _depositEth(ethAmount, beneficiary, actualLiquidityPoolBalance);
    }

    /// @notice Redeems ipstETH tokens for stETH
    /// @param beneficiary Address that will receive stETH tokens
    /// @param ipTokenAmount Amount of ipstETH to burn
    function redeemFromAmmPoolStEth(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(beneficiary, ipTokenAmount);
    }

    /// @notice Rebalances assets between AMM Treasury and Asset Management (Plasma Vault)
    /// @dev Can only be called by appointed rebalancer
    function rebalanceBetweenAmmTreasuryAndAssetManagementStEth() external {
        _rebalanceBetweenAmmTreasuryAndAssetManagement();
    }

    /// @notice Internal function to convert ETH to stETH and mint ipstETH
    /// @dev Calls Lido's submit() function to convert ETH to stETH
    /// @param ethAmount Amount of ETH to convert
    /// @param beneficiary Address that will receive ipstETH tokens
    /// @param actualLiquidityPoolBalance Current liquidity pool balance (for exchange rate calculation)
    function _depositEth(uint256 ethAmount, address beneficiary, uint256 actualLiquidityPoolBalance) private {
        try IStETH(ST_ETH).submit{value: ethAmount}(address(0)) {
            uint256 stEthAmount = IStETH(ST_ETH).balanceOf(address(this));

            if (stEthAmount > 0) {
                uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

                IStETH(ST_ETH).safeTransfer(ammTreasury, stEthAmount);

                uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);

                IIpToken(ipToken).mint(beneficiary, ipTokenAmount);

                emit IAmmPoolsServiceStEth.ProvideLiquidityEth(
                    msg.sender,
                    beneficiary,
                    ammTreasury,
                    exchangeRate,
                    ethAmount,
                    stEthAmount,
                    ipTokenAmount
                );
            }
        } catch {
            revert IAmmPoolsServiceStEth.StEthSubmitFailed({
                amount: ethAmount,
                errorCode: AmmErrors.STETH_SUBMIT_FAILED
            });
        }
    }
}
