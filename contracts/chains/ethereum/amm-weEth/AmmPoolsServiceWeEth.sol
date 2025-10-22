// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../libraries/ProvideLiquidityEvents.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV2.sol";
import "../../../base/amm-weEth/services/AmmPoolsServiceWeEthBaseV1.sol";
import "../../../amm-weEth/interfaces/IAmmPoolsServiceWeEth.sol";
import "../../../amm-weEth/interfaces/IWeEth.sol";
import "../../../amm-weEth/interfaces/IWETH.sol";
import "../../../amm-weEth/interfaces/IEEthLiquidityPool.sol";
import "../../../base/libraries/StorageLibBaseV1.sol";

/// @title AMM Pools Service for weETH with Asset Management support
/// @notice Supports providing liquidity with weETH, eETH, ETH, and WETH
/// @notice Includes auto-rebalancing between AMM Treasury and Asset Management (Plasma Vault)
/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceWeEth is IAmmPoolsServiceWeEth, AmmPoolsServiceWeEthBaseV1 {
    using IporContractValidator for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable eth;
    address public immutable wEth;
    address public immutable eEth;
    address public immutable weEth;
    address public immutable eEthLiquidityPoolExternal; // ether.fi liquidity pool address from mainnet 0x308861A430be4cce5502d0A12724771Fc6DaF216
    address public immutable referral;

    struct DeployedContracts {
        address ethInput;
        address wEthInput;
        address eEthInput;
        address weEthInput;
        address ipWeEthInput;
        address ammTreasuryWeEthInput;
        address ammStorageWeEthInput;
        address ammAssetManagementInput;
        address iporOracleInput;
        address iporProtocolRouterInput;
        uint256 redeemFeeRateWeEthInput;
        address eEthLiquidityPoolExternalInput;
        address referralInput;
        uint256 autoRebalanceThresholdMultiplierInput;
    }

    constructor(
        DeployedContracts memory deployedContracts
    )
        AmmPoolsServiceWeEthBaseV1(
            deployedContracts.weEthInput,
            deployedContracts.ipWeEthInput,
            deployedContracts.ammTreasuryWeEthInput,
            deployedContracts.ammStorageWeEthInput,
            deployedContracts.ammAssetManagementInput,
            deployedContracts.iporOracleInput,
            deployedContracts.iporProtocolRouterInput,
            deployedContracts.redeemFeeRateWeEthInput,
            deployedContracts.autoRebalanceThresholdMultiplierInput
        )
    {
        eth = deployedContracts.ethInput.checkAddress();
        wEth = deployedContracts.wEthInput.checkAddress();
        eEth = deployedContracts.eEthInput.checkAddress();
        weEth = deployedContracts.weEthInput.checkAddress();
        eEthLiquidityPoolExternal = deployedContracts.eEthLiquidityPoolExternalInput.checkAddress();
        referral = deployedContracts.referralInput.checkAddress();
    }

    /// @notice Provides liquidity with various input assets (weETH, eETH, ETH, WETH)
    /// @param poolAsset The pool asset (must be weETH)
    /// @param inputAsset The input asset (weETH, eETH, ETH, or WETH)
    /// @param beneficiary Address that will receive ipweETH tokens
    /// @param inputAssetAmount Amount of input asset to deposit
    /// @return ipTokenAmount Amount of ipweETH tokens minted
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

    /// @notice Provides liquidity directly with weETH
    /// @param beneficiary Address that will receive ipweETH tokens
    /// @param weEthAmount Amount of weETH to deposit
    function provideLiquidityWeEthToAmmPoolWeEth(address beneficiary, uint256 weEthAmount) external override {
        _provideLiquidityWeEthToAmmPoolWeEth(beneficiary, weEthAmount, msg.sender);
    }

    /// @notice Redeems ipweETH tokens for weETH
    /// @param beneficiary Address that will receive weETH tokens
    /// @param ipTokenAmount Amount of ipweETH tokens to redeem
    function redeemFromAmmPoolWeEth(
        address beneficiary,
        uint256 ipTokenAmount
    ) external override(IAmmPoolsServiceWeEth, AmmPoolsServiceWeEthBaseV1) {
        _redeem(beneficiary, ipTokenAmount);
    }

    /// @notice Rebalances assets between AMM Treasury and Asset Management (Plasma Vault)
    /// @dev Can only be called by addresses appointed to rebalance
    function rebalanceBetweenAmmTreasuryAndAssetManagementWeEth()
        external
        override(IAmmPoolsServiceWeEth, AmmPoolsServiceWeEthBaseV1)
    {
        _rebalanceBetweenAmmTreasuryAndAssetManagement();
    }

    /// @notice Internal function to unwrap WETH to ETH
    /// @param wEthAmount Amount of WETH to unwrap
    function _unwrapWethToEth(uint256 wEthAmount) internal {
        IWETH(wEth).safeTransferFrom(msg.sender, iporProtocolRouter, wEthAmount);
        IWETH(wEth).withdraw(wEthAmount);
    }

    /// @notice Internal function to deposit ETH to ether.fi liquidity pool and receive eETH
    /// @param ethAmount Amount of ETH to deposit
    /// @return eEthAmount Amount of eETH received
    function _depositEthToEethLiquidityPoolExternal(uint256 ethAmount) internal returns (uint256 eEthAmount) {
        IEEthLiquidityPool(eEthLiquidityPoolExternal).deposit{value: ethAmount}(referral);
        eEthAmount = IEEthLiquidityPool(eEthLiquidityPoolExternal).getTotalEtherClaimOf(iporProtocolRouter);
        if (eEthAmount == 0) {
            revert IporErrors.WrongAmount(IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER, eEthAmount);
        }
    }

    /// @notice Internal function to wrap eETH to weETH
    /// @param inputAssetAmount Amount of eETH to wrap
    /// @param eEthFrom Address from which to transfer eETH
    /// @return weEthAmount Amount of weETH received
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

    /// @notice Internal function to provide weETH liquidity to the AMM pool
    /// @param beneficiary Address that will receive ipweETH tokens
    /// @param weEthAmount Amount of weETH to deposit
    /// @param weEthFrom Address from which to transfer weETH
    /// @return ipTokenAmount Amount of ipweETH tokens minted
    function _provideLiquidityWeEthToAmmPoolWeEth(
        address beneficiary,
        uint256 weEthAmount,
        address weEthFrom
    ) internal returns (uint256 ipTokenAmount) {
        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            weEth
        );

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV2(ammTreasury).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + weEthAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        if (weEthFrom != iporProtocolRouter) {
            IERC20(weEth).safeTransferFrom(weEthFrom, ammTreasury, weEthAmount);
        } else {
            IERC20(weEth).safeTransfer(ammTreasury, weEthAmount);
        }

        ipTokenAmount = IporMath.division(weEthAmount * 1e18, exchangeRate);

        IIpToken(ipToken).mint(beneficiary, ipTokenAmount);

        /// @dev Order of the following two functions is important, first asset transfer, then rebalance.
        _rebalanceIfNeededAfterProvideLiquidity(ammPoolsParamsCfg, weEthAmount);

        emit ProvideLiquidityEvents.ProvideLiquidity(
            weEth,
            msg.sender,
            beneficiary,
            ammTreasury,
            exchangeRate,
            weEthAmount,
            ipTokenAmount
        );
    }
}
