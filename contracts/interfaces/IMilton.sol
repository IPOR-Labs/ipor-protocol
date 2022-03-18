// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

interface IMilton {
    function getVersion() external pure returns (uint256);

    function getAccruedBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    function calculateSpread() external view returns (uint256 spreadPf, uint256 spreadRf);

    function calculateSoap()
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        );

    function calculateSoap(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        );

    function calculateSwapPayFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    function calculateSwapReceiveFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external returns (uint256);

    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external returns (uint256);

    function closeSwapPayFixed(uint256 swapId) external;

    function closeSwapReceiveFixed(uint256 swapId) external;

    function closeSwapsPayFixed(uint256[] memory swapIds) external;

    function closeSwapsReceiveFixed(uint256[] memory swapIds) external;

    function emergencyCloseSwapPayFixed(uint256 swapId) external;

    function emergencyCloseSwapReceiveFixed(uint256 swapId) external;

    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds) external;

    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds) external;

    function depositToStanley(uint256 assetValue) external;

    function withdrawFromStanley(uint256 assetValue) external;

    function setupMaxAllowance(address spender) external;

    function pause() external;

    function unpause() external;

    // @notice Open swap position
    event OpenSwap(
        uint256 indexed swapId,
        address indexed buyer,
        address asset,
        MiltonTypes.SwapDirection direction,
        AmmTypes.OpenSwapMoney money,
        uint256 openTimestamp,
        uint256 endTimestamp,
        MiltonTypes.IporSwapIndicator indicator
    );

    // @notice Close swap position
    event CloseSwap(
        uint256 indexed swapId,
        address asset,
        uint256 closeTimestamp,
        address liquidator,
        uint256 transferredToBuyer,
        uint256 transferredToLiquidator
    );
}
