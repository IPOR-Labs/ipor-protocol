// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IStakeService.sol";
import "../libraries/errors/PowerTokenErrors.sol";
import "../interfaces/ILiquidityMiningV2.sol";
import "../interfaces/IPowerTokenV2.sol";

contract StakeService is IStakeService {
    using SafeERC20 for IERC20;

    address public immutable LIQUIDITY_MINING_ADDRESS;
    address public immutable POWER_TOKEN_ADDRESS;
    address public immutable STAKED_TOKEN_ADDRESS;

    constructor(
        address liquidityMiningAddress,
        address powerTokenAddress,
        address stakedTokenAddress
    ) {
        LIQUIDITY_MINING_ADDRESS = liquidityMiningAddress;
        POWER_TOKEN_ADDRESS = powerTokenAddress;
        STAKED_TOKEN_ADDRESS = stakedTokenAddress;
    }

    /// @notice Stakes the lpToken amount into the LiquidityMining.
    /// @param lpTokens addresses of the lpToken
    /// @param lpTokenAmounts for lpTokens staked, represented with 18 decimals
    function stakeLpTokens(
        address onBehalfOf,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {
        uint256 lpTokensLength = lpTokens.length;
        require(lpTokensLength == lpTokenAmounts.length, Errors.INPUT_ARRAYS_LENGTH_MISMATCH);
        require(lpTokensLength > 0, Errors.INPUT_ARRAYS_EMPTY);
        require(onBehalfOf != address(0), Errors.WRONG_ADDRESS);
        LiquidityMiningTypes.UpdateLpToken[]
            memory updateLpTokens = new LiquidityMiningTypes.UpdateLpToken[](lpTokensLength);
        for (uint256 i; i != lpTokensLength; ) {
            require(lpTokens[i] != address(0), Errors.WRONG_ADDRESS);
            require(lpTokenAmounts[i] > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);
            uint256 senderBalance = IERC20(lpTokens[i]).balanceOf(msg.sender);
            uint256 transferAmount = senderBalance < lpTokenAmounts[i]
                ? senderBalance
                : lpTokenAmounts[i];

            IERC20(lpTokens[i]).safeTransferFrom(
                msg.sender,
                LIQUIDITY_MINING_ADDRESS,
                transferAmount
            );
            updateLpTokens[i] = LiquidityMiningTypes.UpdateLpToken(
                onBehalfOf,
                lpTokens[i],
                transferAmount
            );

            unchecked {
                ++i;
            }
        }

        ILiquidityMiningV2(LIQUIDITY_MINING_ADDRESS).addLpTokens(updateLpTokens);
    }

    function unstakeLpTokens(
        address transferTo,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {
        uint256 lpTokensLength = lpTokens.length;
        require(lpTokensLength == lpTokenAmounts.length, Errors.INPUT_ARRAYS_LENGTH_MISMATCH);
        require(lpTokensLength > 0, Errors.INPUT_ARRAYS_EMPTY);
        LiquidityMiningTypes.UpdateLpToken[]
            memory updateLpTokens = new LiquidityMiningTypes.UpdateLpToken[](lpTokensLength);

        for (uint256 i; i != lpTokensLength; ) {
            require(lpTokens[i] != address(0), Errors.WRONG_ADDRESS);
            require(lpTokenAmounts[i] > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);

            updateLpTokens[i] = LiquidityMiningTypes.UpdateLpToken(
                msg.sender,
                lpTokens[i],
                lpTokenAmounts[i]
            );

            unchecked {
                ++i;
            }
        }

        ILiquidityMiningV2(LIQUIDITY_MINING_ADDRESS).removeLpTokens(updateLpTokens);

        for (uint256 i; i != lpTokensLength; ) {
            IERC20(lpTokens[i]).safeTransferFrom(
                LIQUIDITY_MINING_ADDRESS,
                transferTo,
                lpTokenAmounts[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function stakeProtocolToken(address onBehalfOf, uint256 iporTokenAmount) external {
        require(onBehalfOf != address(0), Errors.WRONG_ADDRESS);
        require(iporTokenAmount > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);

        IPowerTokenV2(POWER_TOKEN_ADDRESS).addStakedToken(
            PowerTokenTypes.UpdateStakedToken(onBehalfOf, iporTokenAmount)
        );

        IERC20(STAKED_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            POWER_TOKEN_ADDRESS,
            iporTokenAmount
        );
    }

    function unstakeProtocolToken(address transferTo, uint256 iporTokenAmount) external {
        require(iporTokenAmount > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);

        uint256 stakedTokenAmountToTransfer = IPowerTokenV2(POWER_TOKEN_ADDRESS)
            .removeStakedTokenWithFee(
                PowerTokenTypes.UpdateStakedToken(msg.sender, iporTokenAmount)
            );

        IERC20(STAKED_TOKEN_ADDRESS).safeTransferFrom(
            POWER_TOKEN_ADDRESS,
            transferTo,
            stakedTokenAmountToTransfer
        );
    }

    function cooldown(uint256 pwTokenAmount) external {
        require(pwTokenAmount > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);
        IPowerTokenV2(POWER_TOKEN_ADDRESS).cooldown(msg.sender, pwTokenAmount);
    }

    function cancelCooldown() external {
        IPowerTokenV2(POWER_TOKEN_ADDRESS).cancelCooldown(msg.sender);
    }

    function redeem(address transferTo) external {
        uint256 transferAmount = IPowerTokenV2(POWER_TOKEN_ADDRESS).redeem(msg.sender);
        ///@dev We can transfer pwTokenAmount because it is in relation 1:1 to Staked Token
        IERC20(STAKED_TOKEN_ADDRESS).safeTransferFrom(
            POWER_TOKEN_ADDRESS,
            transferTo,
            transferAmount
        );
    }
}
