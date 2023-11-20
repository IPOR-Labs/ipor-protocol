// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsServiceEth contract.
interface IAmmPoolsServiceStEth {
    /// @notice Allows the router to provide liquidity in the form of stEth to the AMM pool.
    /// @param beneficiary Address that will receive the minted ipstEth tokens in exchange for the provided stEth.
    /// @param stEthAmount Amount of stEth tokens to be provided as liquidity.
    /// @dev This function can only be called by the router. It calculates the new pool balance, checks if it's within the allowed limit,
    /// calculates the exchange rate, transfers the stEth from the sender to the AmmTreasury contract, and mints ipstEth tokens to the beneficiary.
    /// An event IAmmPoolsServiceStEth.ProvideLiquidityStEth is emitted after the liquidity is provided.
    /// require the new pool balance after adding the provided stEth should not exceed the maximum allowed pool balance.
    function provideLiquidityStEth(address beneficiary, uint256 stEthAmount) external payable;

    /// @notice Allows the router to provide liquidity in the form of wEth to the AMM pool.
    /// @param beneficiary Address that will benefit from the provided liquidity.
    /// @param assetAmount Amount of wEth tokens to be provided as liquidity.
    /// @dev This function can only be called by the router. It checks the validity of the provided wEth amount and beneficiary address,
    /// calculates the new pool balance, checks if it's within the allowed limit.
    /// @dev Flow is following: Transfers the wEth from the sender to Router contract, Router withdraws the wEth to convert it to Ether,
    /// Router submit  the Ether to stETH contract and transfer stETH to AmmTreasury contract, mints ipstETH to the beneficiary.
    /// An event IAmmPoolsServiceStEth.ProvideLiquidityEth is emitted after the liquidity is provided.
    /// require The provided wEth amount should be greater than zero.
    /// require The beneficiary address should not be the zero address.
    /// require The new pool balance after adding the provided wEth should not exceed the maximum allowed pool balance.
    function provideLiquidityWEth(address beneficiary, uint256 assetAmount) external payable;

    /// @notice Allows the router to provide liquidity in the form of Ether to the AMM pool.
    /// @param beneficiary Address that will benefit from the provided liquidity.
    /// @param assetAmount Amount of Ether to be provided as liquidity.
    /// @dev This function can only be called by the router. It checks the validity of the provided Ether amount, the sent Ether value,
    /// and the beneficiary address, calculates the new pool balance, and checks if it's within the allowed limit.
    /// @dev Flow is following: User transfer to Router ETH, Router submit ETH to stETH contract and transfer stETH to AmmTreasury contract,
    /// Router mints ipstETH to the beneficiary.
    /// An event IAmmPoolsServiceStEth.ProvideLiquidityEth is emitted after the liquidity is provided.
    /// require The provided Ether amount should be greater than zero.
    /// require The sent Ether value with the transaction should be greater than zero.
    /// require The beneficiary address should not be the zero address.
    /// require The new pool balance after adding the provided Ether should not exceed the maximum allowed pool balance.
    function provideLiquidityEth(address beneficiary, uint256 assetAmount) external payable;

    /// @notice Allows the router to redeem stEth from the AMM pool in exchange for ipstEth tokens.
    /// @param beneficiary Address that will receive the redeemed stEth.
    /// @param ipTokenAmount Amount of ipstEth tokens to be redeemed.
    /// @dev This function can only be called by the router. It checks the validity of the provided ipstEth amount and beneficiary address,
    /// calculates the exchange rate, determines the amount of stEth equivalent to the provided ipstEth, and transfers the stEth to the beneficiary.
    /// The function also accounts for a redemption fee. An event is emitted after the redemption.
    /// require The provided ipstEth amount should be greater than zero and less than or equal to the sender's balance.
    /// require The beneficiary address should not be the zero address.
    /// require The calculated stEth amount to redeem after accounting for the fee should be greater than zero.
    function redeemFromAmmPoolStEth(address beneficiary, uint256 ipTokenAmount) external;

    /// @notice Error appeared when submitted ETH amount to in stETH contract is too high.
    /// @param amount Amount of ETH which was submitted to stETH contract.
    /// @param errorCode IPOR Protocol error code.
    error StEthSubmitFailed(uint256 amount, string errorCode);

    /// @notice Event emitted when liquidity is provided in the form of stEth.
    /// @param from Address of the sender.
    /// @param beneficiary Address that will receive the minted ipstEth tokens in exchange for the provided stEth.
    /// @param to Address of the AMM treasury.
    /// @param exchangeRate Exchange rate between stEth and ipstEth.
    /// @param assetAmount Amount of stEth tokens provided as liquidity.
    /// @param ipTokenAmount Amount of ipstEth tokens minted in exchange for the provided stEth.
    event ProvideLiquidityStEth(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    /// @notice Event emitted when liquidity is provided in the form of wEth or ETH.
    /// @param from Address of the sender.
    /// @param beneficiary Address that will benefit from the provided liquidity.
    /// @param to Address of the AMM treasury.
    /// @param exchangeRate Exchange rate between wEth and ipstEth.
    /// @param amountEth Amount of ETH provided as liquidity.
    /// @param amountStEth Amount of stEth tokens submitted to StETH contract based on amountEth
    /// @param ipTokenAmount Amount of ipstEth tokens minted in exchange for the provided stEth.
    event ProvideLiquidityEth(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 amountEth,
        uint256 amountStEth,
        uint256 ipTokenAmount
    );

    /// @notice Event emitted when liquidity is redeemed from the AMM pool in exchange for stEth.
    /// @param ammTreasuryEth Address of the AMM Treasury stETH contract.
    /// @param from Address of the sender. From who ipstEth tokens were burned.
    /// @param beneficiary Address that will receive the redeemed stEth tokens.
    /// @param exchangeRate Exchange rate between stEth and ipstEth.
    /// @param amountStEth Amount of stEth tokens redeemed.
    /// @param redeemedAmountStEth Amount of stEth tokens redeemed after accounting for the fee.
    /// @param ipTokenAmount Amount of ipstEth tokens redeemed.
    event RedeemStEth(
        address indexed ammTreasuryEth,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountStEth,
        uint256 redeemedAmountStEth,
        uint256 ipTokenAmount
    );
}
