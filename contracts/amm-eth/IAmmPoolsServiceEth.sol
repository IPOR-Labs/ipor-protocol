// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAmmPoolsServiceEth {
    /// @notice Allows the router to provide liquidity in the form of stEth to the AMM pool.
    /// @param beneficiary Address that will receive the minted ipstEth tokens in exchange for the provided stEth.
    /// @param stEthAmount Amount of stEth tokens to be provided as liquidity.
    /// @dev This function can only be called by the router. It calculates the new pool balance, checks if it's within the allowed limit,
    /// calculates the exchange rate, transfers the stEth from the sender to the AMM treasury, and mints ipstEth tokens to the beneficiary.
    /// An event is emitted after the liquidity is provided.
    /// require The new pool balance after adding the provided stEth should not exceed the maximum allowed pool balance.
    function provideLiquidityStEth(address beneficiary, uint256 stEthAmount) external payable;

    /// @notice Allows the router to provide liquidity in the form of wEth to the AMM pool.
    /// @param beneficiary Address that will benefit from the provided liquidity.
    /// @param assetAmount Amount of wEth tokens to be provided as liquidity.
    /// @dev This function can only be called by the router. It checks the validity of the provided wEth amount and beneficiary address,
    /// calculates the new pool balance, checks if it's within the allowed limit, transfers the wEth from the sender to the contract,
    /// withdraws the wEth to convert it to Ether, and then deposits the Ether to the beneficiary.
    /// require The provided wEth amount should be greater than zero.
    /// require The beneficiary address should not be the zero address.
    /// require The new pool balance after adding the provided wEth should not exceed the maximum allowed pool balance.
    function provideLiquidityWEth(address beneficiary, uint256 assetAmount) external payable;

    /// @notice Allows the router to provide liquidity in the form of Ether to the AMM pool.
    /// @param beneficiary Address that will benefit from the provided liquidity.
    /// @param assetAmount Amount of Ether to be provided as liquidity.
    /// @dev This function can only be called by the router. It checks the validity of the provided Ether amount, the sent Ether value,
    /// and the beneficiary address, calculates the new pool balance, and checks if it's within the allowed limit.
    /// The Ether is then deposited to the beneficiary.
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

    error StEthSubmitFailed(uint256 amount, string errorCode);

    event ProvideLiquidityStEth(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event ProvideLiquidityEth(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 amountEth,
        uint256 amountStEth,
        uint256 ipTokenAmount
    );

    event RedeemStEth(
        uint256 timestamp,
        address tresury,
        address from,
        address beneficiary,
        uint256 exchangeRate,
        uint256 ipTokenAmount,
        uint256 assetAmount,
        uint256 redeemAmount
    );
}
