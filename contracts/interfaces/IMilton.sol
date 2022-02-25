// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMilton {
    function getVersion() external pure returns (uint256);

    function authorizeJoseph(address joseph) external;

    function pause() external;

    function unpause() external;

    function depositToVault(uint256 assetValue)
        external
        returns (uint256 currentBalance, uint256 currentInterest);

    function withdrawFromVault(uint256 ivTokenValue)
        external
        returns (uint256 withdrawAssetValue, uint256 currentInterest);

    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external returns (uint256);

    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external returns (uint256);

    function closeSwapPayFixed(uint256 swapId) external;

    function closeSwapReceiveFixed(uint256 swapId) external;

    function calculateSoap()
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        );

    function calculateSpread()
        external
        view
        returns (uint256 spreadPf, uint256 spreadRf);

    function calculateSwapPayFixedValue(DataTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    function calculateSwapReceiveFixedValue(
        DataTypes.IporSwapMemory memory swap
    ) external view returns (int256);

    function calculateExchangeRate(uint256 calculateTimestamp)
        external
        view
        returns (uint256);

    function getAccruedBalance()
        external
        view
        returns (DataTypes.MiltonBalanceMemory memory);
}
