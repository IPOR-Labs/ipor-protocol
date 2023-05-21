// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/types/AmmTypes.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "./MiltonInternal.sol";
import "./libraries/types/AmmMiltonTypes.sol";
import "./MiltonStorage.sol";

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
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    function calculateSoap()
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(block.timestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
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
