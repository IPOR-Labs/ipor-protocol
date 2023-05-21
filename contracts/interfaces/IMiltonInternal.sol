// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for issuing and closing interest rate swaps also known as Automated Market Maker - administrative part.
interface IMiltonInternal {
    /// @notice Returns current version of Milton
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return Current Milton's version
    function getVersion() external pure returns (uint256);


    /// @notice Calculates SOAP at given timestamp.
    /// @dev returned values represented in 18 decimals
    /// @param calculateTimestamp epoch timestamp at which SOAP is computed.
    /// @return soapPayFixed SOAP for Pay-Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive-Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculats Pay-Fixed Swap payoff for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Pay-Fixed Swap payoff, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than the collateral
    function calculatePayoffPayFixed(IporTypes.IporSwapMemory memory swap) external view returns (int256);

    /// @notice Calculats Receive-Fixed swap payoff for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Receive Fixed Swap payoff, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than the collateral
    function calculatePayoffReceiveFixed(IporTypes.IporSwapMemory memory swap) external view returns (int256);

    /// @notice Transfers the assets from Milton to Stanley. Action available only to Joseph.
    /// @dev Milton balance in storage is not changing after this deposit, balance of ERC20 assets on Milton is changing as they get transfered to Stanley.
    /// @dev Emits {Deposit} event from Stanley, emits {Transfer} event from ERC20, emits {Mint} event from ivToken
    /// @param assetAmount amount of asset
    function depositToStanley(uint256 assetAmount) external;

    /// @notice Transfers the assets from Stanley to Milton. Action available only for Joseph.
    /// @dev Milton balance in storage is not changing, balance of ERC20 assets of Milton is changing.
    /// @dev Emits {Withdraw} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param assetAmount amount of assets
    function withdrawFromStanley(uint256 assetAmount) external;

    /// @notice Transfers assets (underlying tokens / stablecoins) from Stanley to Milton. Action available only for Joseph.
    /// @dev Milton Balance in storage is not changing after this wi, balance of ERC20 assets on Milton is changing.
    /// @dev Emits {Withdraw} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    function withdrawAllFromStanley() external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of Milton
    function setupMaxAllowanceForAsset(address spender) external;

}
