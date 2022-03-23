// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Joseph's configuration.
interface IJosephConfiguration {
    /// @notice Gets Charlie Treasury address, external multisig wallet where Milton IPOR publication fee balance is transferred.
    /// @return Charlie Treasury address
    function getCharlieTreasury() external view returns (address);

    /// @notice Sets Charlie Treasury address
    /// @param newCharlieTreasury new Charlie Treasury address
    function setCharlieTreasury(address newCharlieTreasury) external;

    /// @notice Gets Treasury address, external multisig wallet where Milton Treasury balance is transferred.
    /// @dev Part of opening fee goes to Milton Treasury balance and from time to time is transfered to multisig wallet Treasury
    /// @return Treasury address
    function getTreasury() external view returns (address);

    /// @notice Sets Treasury address
    /// @param newTreasury new Treasury address
    function setTreasury(address newTreasury) external;

    /// @notice Gets Charlie Treasury Manager address, external multisig address which has permission to transfer Charlie Treasury balance from Milton to external Charlie Treausyr wallet.
    /// @return Charlie Treasury Manager address
    function getCharlieTreasuryManager() external view returns (address);

    /// @notice Sets Charlie Treasury Manager address
    /// @param newCharlieTreasuryManager new Charlie Treasury Manager address
    function setCharlieTreasuryManager(address newCharlieTreasuryManager) external;

    /// @notice Gets Treasury Manager address, external multisig address which has permission to transfer Treasury balance from Milton to external Treausry wallet.
    /// @return Treasury Manager address
    function getTreasuryManager() external view returns (address);

    /// @notice Sets Treasury Manager address
	/// 
    function setTreasuryManager(address treasuryManager) external;

    /// @notice
    /// @return
    function getRedeemFeePercentage() external pure returns (uint256);

    /// @notice
    /// @return
    function getRedeemLpMaxUtilizationPercentage() external pure returns (uint256);

    /// @notice
    /// @return
    function getMiltonStanleyBalancePercentage() external pure returns (uint256);

    /// @notice
    /// @return
    function asset() external view returns (address);

    /// @notice
    event CharlieTreasuryUpdated(address indexed asset, address indexed newCharlieTreasury);

    /// @notice
    event CharlieTreasuryManagerUpdated(address indexed newCharlieTreasuryManager);

    /// @notice
    event TreasuryManagerUpdated(address indexed newTreasuryManager);

    /// @notice
    event TreasuryUpdated(address indexed asset, address indexed newTreasury);
}
