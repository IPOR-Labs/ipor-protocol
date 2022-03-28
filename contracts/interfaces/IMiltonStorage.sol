// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonStorageTypes.sol";

/// @title Interface for interaction with Milton Storage smart contract, which is reposnsible for managing AMM storage.
interface IMiltonStorage {
    /// @notice Returns current version of Milton Storage's
    /// @return current Milton Storage version, this is integer.
    function getVersion() external pure returns (uint256);

    /// @notice Gets lasw swap Id.
    /// @dev swap id is incremented when new position is opened, last swap id is used in Pay Fixed and Receive Fixed swaps.
    /// @return last swap id, this is integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets balance struct
    /// @dev Balance contain, Pay Fixed Total Collateral, Receive Fixed Total Collateral, Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.MiltonBalancesMemory}
    function getBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    /// @notice Gets balance with extended information like IPOR publication fee balance and Treasury balance.
    /// @return balance structure {MiltonStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance()
        external
        view
        returns (MiltonStorageTypes.ExtendedBalancesMemory memory);

    /// @notice Gets total outstanding notional.
    /// @return payFixedTotalNotional total notional balance for Pay Fixed leg, represented in 18 decimals
    /// @return recFixedTotalNotional total notional balance for Receive Fixed leg, represented in 18 decimals
    function getTotalOutstandingNotional()
        external
        view
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional);

    /// @notice Gets Pay Fixed Swap for a given swap id
    /// @param swapId swap id.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapPayFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets Receive Fixed Swap for a given swap id
    /// @param swapId swap id.
    /// @return swap structure {IporTypes.IporSwapMemory}
    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        returns (IporTypes.IporSwapMemory memory);

    /// @notice Gets Pay Fixed active swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay Fixed swaps
    /// @return swaps array where one element is {IporTypes.IporSwapMemory}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets Receive Fixed active swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed swaps
    /// @return swaps array where one element is {IporTypes.IporSwapMemory}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets Pay Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay Fixed Ids
    /// @return ids list of ids
    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

    /// @notice Gets Receive Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed Ids
    /// @return ids list of ids
    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, uint128[] memory ids);

    /// @notice Gets Pay Fixed and Receive Fixed ids of active swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay Fixed and Receive Fixed Ids with theirs direction.
    /// @return swaps array where one element is {MiltonStorageTypes.IporSwapId}
    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids);

    /// @notice Calculates total SOAP for a given IBT price and calculation timestamp.
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapPayFixed SOAP for Pay Fixed and Receive Floating Leg, represented in 18 decimals
    /// @return soapReceiveFixed SOAP for Receive Fixed and Pay Floating Leg, represented in 18 decimals
    /// @return soap total SOAP Pay Fixed Leg and Receive Fixed Leg , represented in 18 decimals
    function calculateSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculates SOAP for Pay Fixed Leg for a given IBT price and time.
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapPayFixed SOAP for Pay Fixed leg, represented in 18 decimals
    function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (int256 soapPayFixed);

    /// @notice Calculates SOAP for Receive Fixed Leg for a given IBT price and time.
    /// @param ibtPrice IBT (Interest Bearing Token) price
    /// @param calculateTimestamp epoch timestamp, the time for which SOAP is calculated
    /// @return soapReceiveFixed SOAP for Receive Fixed leg, represented in 18 decimals
    function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        returns (int256 soapReceiveFixed);

    /// @notice add liquidity to Liquidity Pool balance in storage.
    /// @param assetAmount amount of asset which is added to Liquidity Pool balance, represented in 18 decimals
    function addLiquidity(uint256 assetAmount) external;

    /// @notice substract liquyidity from Liquidity Pool balance in storage.
    /// @param assetAmount amount of asset which is substracted from Liquidity Pool balance, represented in 18 decimals
    function subtractLiquidity(uint256 assetAmount) external;

    /// @notice Updates structures in storage - balance, swaps, SOAP indicators when new pay fixed swap is opened.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFeeAmount publication fee amount taken from Milton configuration, represented in 18 decimals.
    /// @return new swap Id
    function updateStorageWhenOpenSwapPayFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFeeAmount
    ) external returns (uint256);

    /// @notice Updates structures in storage - balance, swaps, SOAP indicators when new receive fixed swap is opened.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFeeAmount publication fee amount taken from Milton configuration, represented in 18 decimals.
    /// @return new swap Id
    function updateStorageWhenOpenSwapReceiveFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFeeAmount
    ) external returns (uint256);

    /// @notice Updates structures in storage - balance, swaps, SOAP indicators when close pay fixed swap.
    /// @param liquidator account address who closes swap
    /// @param iporSwap swap structure {IporTypes.IporSwapMemory}
    /// @param positionValue amount which trader earned or lost for this bet, represented in 18 decimals, can be negative.
    /// @param closingTimestamp moment when swap is closed
    /// @param cfgIncomeFeePercentage income fee percentage taken from trader profit positionValue, configuration param represented in 18 decimals
    /// @param cfgMinPercentagePositionValueToCloseBeforeMaturity configuration param for validation closing swap, describe minimal percentage
    /// position value required to close swap before maturity. Value represented in 18 decimals.
    /// @param cfgSecondsToMaturityWhenPositionCanBeClosed configuration param for validation closing swap, describe number of seconds before swap
    ///maturity after which swap can be closed by anybody not only by swap's buyer.
    function updateStorageWhenCloseSwapPayFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeePercentage,
        uint256 cfgMinPercentagePositionValueToCloseBeforeMaturity,
        uint256 cfgSecondsToMaturityWhenPositionCanBeClosed
    ) external;

    /// @notice Updates structures in storage - balance, swaps, SOAP indicators when close receive fixed swap.
    /// @param liquidator account address who closes swap
    /// @param iporSwap swap structure {IporTypes.IporSwapMemory}
    /// @param positionValue amount which trader earned or lost for this bet, represented in 18 decimals, can be negative.
    /// @param closingTimestamp moment when swap is closed
    /// @param cfgIncomeFeePercentage income fee percentage taken from trader profit positionValue, configuration param represented in 18 decimals
    /// @param cfgMinPercentagePositionValueToCloseBeforeMaturity configuration param for validation closing swap, describe minimal percentage
    /// position value required to close swap before maturity. Value represented in 18 decimals.
    /// @param cfgSecondsToMaturityWhenPositionCanBeClosed configuration param for validation closing swap, describe number of seconds before swap
    ///maturity after which swap can be closed by anybody not only by swap's buyer.
    function updateStorageWhenCloseSwapReceiveFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeePercentage,
        uint256 cfgMinPercentagePositionValueToCloseBeforeMaturity,
        uint256 secondsToMaturityWhenPositionCanBeClosed
    ) external;

    /// @notice Updates balance when Joseph withdraws Milton's cash from Stanley.
    /// @param withdrawnAmount asset amount which was withdrawn from Stanley to Milton by Joseph, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault balance, represented in 18 decimals
    function updateStorageWhenWithdrawFromStanley(uint256 withdrawnAmount, uint256 vaultBalance)
        external;

    /// @notice Updates balance when Joseph deposits Milton's cash to Stanley.
    /// @param depositAmount asset amount which was deposited from Milton to Stanley by Joseph, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault balance (Stanley's balance), represented in 18 decimals
    function updateStorageWhenDepositToStanley(uint256 depositAmount, uint256 vaultBalance)
        external;

    /// @notice Updates balance when Joseph transfers Milton's cash to Charlie Treasury's multisig wallet.
    /// @param transferredAmount asset amount which is transferred to Charlie Treasury multisig wallet.
    function updateStorageWhenTransferToCharlieTreasury(uint256 transferredAmount) external;

    /// @notice Updates balance when Joseph transfers Milton's cash to Treasury's multisig wallet.
    /// @param transferredAmount asset amount which is transferred to Treasury multisig wallet.
    function updateStorageWhenTransferToTreasury(uint256 transferredAmount) external;

    /// @notice Sets Milton address. Function available only for smart contract Owner.
    /// @param milton Milton address
    function setMilton(address milton) external;

    /// @notice Sets Joseph address. Function available only for smart contract Owner.
    /// @param joseph Joseph address
    function setJoseph(address joseph) external;

    /// @notice Emmited when Milton address changed by smart contract Owner.
    /// @param changedBy account address who changed Milton address
    /// @param oldMilton old Milton address
    /// @param newMilton new Milton address
    event MiltonChanged(address changedBy, address oldMilton, address newMilton);

    /// @notice Emmited when Joseph address changed by smart contract Owner.
    /// @param changedBy account address who changed Jospeh address
    /// @param oldJoseph old Joseph address
    /// @param newJoseph new Joseph address
    event JosephChanged(address changedBy, address oldJoseph, address newJoseph);

    //TODO: pause and unpause
}
