// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/types/AmmTypes.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IAmmPoolsServiceStEth.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceStEth is IAmmPoolsServiceStEth {
    using IporContractValidator for address;
    using SafeERC20 for IStETH;
    using SafeERC20 for IWETH9;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryStEth;
    address public immutable ammStorageStEth;
    address public immutable iporOracle;
    address public immutable iporProtocolRouter;
    uint256 public immutable redeemFeeRateStEth;

    constructor(
        address stEthInput,
        address wEthInput,
        address ipstEthInput,
        address ammTreasuryStEthInput,
        address ammStorageStEthInput,
        address iporOracleInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateStEthInput
    ) {
        stEth = stEthInput.checkAddress();
        wEth = wEthInput.checkAddress();
        ipstEth = ipstEthInput.checkAddress();
        ammTreasuryStEth = ammTreasuryStEthInput.checkAddress();
        ammStorageStEth = ammStorageStEthInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        redeemFeeRateStEth = redeemFeeRateStEthInput;

        require(redeemFeeRateStEthInput <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);
    }

    function provideLiquidityStEth(address beneficiary, uint256 stEthAmount) external payable override {
        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            stEth
        );

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryStEth).getLiquidityPoolBalance();
        uint256 newPoolBalance = actualLiquidityPoolBalance + stEthAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IStETH(stEth).safeTransferFrom(msg.sender, ammTreasuryStEth, stEthAmount);

        uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);

        IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

        emit IAmmPoolsServiceStEth.ProvideLiquidityStEth(
            msg.sender,
            beneficiary,
            ammTreasuryStEth,
            exchangeRate,
            stEthAmount,
            ipTokenAmount
        );
    }

    function provideLiquidityWEth(address beneficiary, uint256 wEthAmount) external payable override {
        require(wEthAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            stEth
        );
        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryStEth).getLiquidityPoolBalance();
        uint256 newPoolBalance = wEthAmount + actualLiquidityPoolBalance;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        IWETH9(wEth).safeTransferFrom(msg.sender, iporProtocolRouter, wEthAmount);
        IWETH9(wEth).withdraw(wEthAmount);

        _depositEth(wEthAmount, beneficiary, actualLiquidityPoolBalance);
    }

    function provideLiquidityEth(address beneficiary, uint256 ethAmount) external payable {
        require(ethAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        require(msg.value > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        StorageLibBaseV1.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            stEth
        );
        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryStEth).getLiquidityPoolBalance();
        uint256 newPoolBalance = ethAmount + actualLiquidityPoolBalance;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        _depositEth(ethAmount, beneficiary, actualLiquidityPoolBalance);
    }

    function redeemFromAmmPoolStEth(address beneficiary, uint256 ipTokenAmount) external {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipstEth).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryStEth).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 stEthAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.division(stEthAmount * (1e18 - redeemFeeRateStEth), 1e18);

        require(amountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        IIpToken(ipstEth).burn(msg.sender, ipTokenAmount);

        IStETH(stEth).safeTransferFrom(ammTreasuryStEth, beneficiary, amountToRedeem);

        emit RedeemStEth(
            ammTreasuryStEth,
            msg.sender,
            beneficiary,
            exchangeRate,
            stEthAmount,
            amountToRedeem,
            ipTokenAmount
        );
    }

    function _depositEth(uint256 ethAmount, address beneficiary, uint256 actualLiquidityPoolBalance) private {
        try IStETH(stEth).submit{value: ethAmount}(address(0)) {
            uint256 stEthAmount = IStETH(stEth).balanceOf(address(this));

            if (stEthAmount > 0) {
                uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

                IStETH(stEth).safeTransfer(ammTreasuryStEth, stEthAmount);

                uint256 ipTokenAmount = IporMath.division(stEthAmount * 1e18, exchangeRate);

                IIpToken(ipstEth).mint(beneficiary, ipTokenAmount);

                emit IAmmPoolsServiceStEth.ProvideLiquidityEth(
                    msg.sender,
                    beneficiary,
                    ammTreasuryStEth,
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

    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: stEth,
            assetDecimals: 18,
            ipToken: ipstEth,
            ammStorage: ammStorageStEth,
            ammTreasury: ammTreasuryStEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }

    /// @notice Rebalancing is not supported in this legacy V1 contract
    /// @dev This function is here for interface compatibility only
    /// @dev Use the V2 contract (contracts/chains/ethereum/amm-stEth/AmmPoolsServiceStEth.sol) for rebalancing support
    function rebalanceBetweenAmmTreasuryAndAssetManagementStEth() external pure {
        revert("IPOR_901"); // Rebalancing not supported in V1 contract
    }
}
