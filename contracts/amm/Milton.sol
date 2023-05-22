// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IMilton.sol";
import "./MiltonInternal.sol";

/**
 * @title Milton - Automated Market Maker for trading Interest Rate Swaps derivatives based on IPOR Index.
 * @dev Milton is scoped per asset (USDT, USDC, DAI or other type of ERC20 asset included by the DAO)
 * Users can:
 *  # open and close own interest rate swaps
 *  # liquidate other's swaps at maturity
 *  # calculate the SOAP
 *  # calculate spread
 * @author IPOR Labs
 */
contract Milton is MiltonInternal, IMilton {
    constructor(
        address asset,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address iporProtocolRouter
    ) MiltonInternal(asset, decimals, ammStorage, assetManagement, iporProtocolRouter) {}

    function getVersion() external pure returns (uint256) {
        return 11;
    }

    function getConfiguration()
        external
        view
        override
        returns (
            address asset,
            uint256 decimals,
            address ammStorage,
            address assetManagement,
            address iporProtocolRouter
        )
    {
        return (_asset, _decimals, _ammStorage, _assetManagement, _iporProtocolRouter);
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
