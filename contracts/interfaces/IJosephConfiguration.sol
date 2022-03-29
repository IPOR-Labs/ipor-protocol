// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Joseph's configuration.
interface IJosephConfiguration {
    /// @notice Returns current version of Joseph's
    /// @return current Joseph version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Joseph instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets Charlie Treasury address, external multisig wallet where Milton IPOR publication fee balance is transferred.
    /// @return Charlie Treasury address
    function getCharlieTreasury() external view returns (address);

    /// @notice Gets Treasury address, external multisig wallet where Milton Treasury balance is transferred.
    /// @dev Part of opening fee goes to Milton Treasury balance and from time to time is transfered to multisig wallet Treasury
    /// @return Treasury address
    function getTreasury() external view returns (address);

    /// @notice Gets Charlie Treasury Manager address, external multisig address which has permission to transfer Charlie Treasury balance from Milton to external Charlie Treausyr wallet.
    /// @return Charlie Treasury Manager address
    function getCharlieTreasuryManager() external view returns (address);

    /// @notice Gets Treasury Manager address, external multisig address which has permission to transfer Treasury balance from Milton to external Treausry wallet.
    /// @return Treasury Manager address
    function getTreasuryManager() external view returns (address);

    /// @notice Gets redeem fee percentage config param which is used in calculation redeem fee taken by Joseph when trader redeem his ipTokens
    /// @return redeem fee percentage represented in 18 decimals
    function getRedeemFeePercentage() external pure returns (uint256);

    /// @notice Gets redeem Liquidity Pool max utilization percentage config param which is used by Joseph to validate Liquidity Pool utilization rate treshold during redeeming ipTokens by trader.
    /// @return redeem Liquidity Pool max utilization percentage
    function getRedeemLpMaxUtilizationPercentage() external pure returns (uint256);

    /// @notice Gets balance ratio config param presented in percentages in 18 decimals between Milton and Stanley
    /// @return gets balance ratio config param between Milton and Stanley
    function getMiltonStanleyBalanceRatioPercentage() external pure returns (uint256);
}
