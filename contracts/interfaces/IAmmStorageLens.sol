// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IAmmStorageLens {
    /// @notice Calculates spread for the current block.
    /// @dev All values represented in 18 decimals.
    /// @param asset Address of the asset.
    /// @return spreadPayFixed spread for Pay-Fixed leg.
    /// @return spreadReceiveFixed spread for Receive-Fixed leg.
    function calculateSpread(address asset) external view returns (int256 spreadPayFixed, int256 spreadReceiveFixed);

    /// @notice Calculates the SOAP for the current block
    /// @dev All values represented in 18 decimals.
    /// @param asset Address of the asset.
    /// @return soapPayFixed SOAP for Pay-Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive-Fixed leg.
    /// @return soap total SOAP - sum of Pay-Fixed and Receive-Fixed SOAP.
    function calculateSoap(address asset)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Get closable status for Pay-Fixed swap.
    /// @param asset Address of the asset.
    /// @param swapId Pay-Fixed swap ID.
    /// @return closableStatus Closable status for Pay-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForPayFixedSwap(address asset, uint256 swapId)
        external
        view
        returns (uint256 closableStatus);

    /// @notice Get closable status for Receive-Fixed swap.
    /// @param asset Address of the asset.
    /// @param swapId Receive-Fixed swap ID.
    /// @return closableStatus Closable status for Receive-Fixed swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatusForReceiveFixedSwap(address asset, uint256 swapId)
        external
        view
        returns (uint256 closableStatus);
}
