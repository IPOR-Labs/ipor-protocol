// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStanley {
    /// @notice Returns current version of Stanley's
    /// @return current Stanley version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Stanley instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    //@notice return amount of assset token always in 18 decimals
    function totalBalance(address who) external view returns (uint256);

    function calculateExchangeRate() external view returns (uint256);

    //@notice in return balance before deposit
    //@dev input and output values are represented in 18 decimals
    //@param amount - deposited amount
    //@return current balance
    function deposit(uint256 amount) external returns (uint256 vaultBalance);

    //@notice withdraw specific amount of stable
    //@dev input and output values are represented in 18 decimals
    //@param amount - deposited amount
    //@return withdrawnValue final withdrawn value of underlying tokens, widthdrawnValue can be different
    //than amount because balance on strategy site can be too low or exchangeRate of shareToken could change
    //or calculation could influence on final value.
    //@return balance - current balance in all strategies
    function withdraw(uint256 amount)
        external
        returns (uint256 withdrawnValue, uint256 vaultBalance);

    function withdrawAll() external returns (uint256 withdrawnValue, uint256 vaultBalance);

    event Deposit(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenValue
    );

    event Withdraw(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenValue
    );

    event MiltonChanged(address changedBy, address newMilton);
}
