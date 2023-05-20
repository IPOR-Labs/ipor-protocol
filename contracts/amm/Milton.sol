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
abstract contract Milton is MiltonInternal, IMilton {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor() {
        _disableInitializers();
    }

    /**
     * @param paused - Initial flag to determine if smart contract is paused or not
     * @param asset - Instance of Milton is initialised in the context of the given ERC20 asset. Every trasaction is by the default scoped to that ERC20.
     * @param iporOracle - Address of Oracle treated as the source of true IPOR rate.
     * @param miltonStorage - Address of contract responsible for managing the state of Milton.
     * @param miltonSpreadModel - Address of smart contract responsible for calculating spreads on the interst rate swaps.
     * @param stanley - Address of smart contract responsible for asset management.
     * For more details refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
     **/

    function initialize(
        bool paused,
        address asset,
        address iporOracle,
        address miltonStorage,
        address miltonSpreadModel,
        address stanley
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        if (paused) {
            _pause();
        }

        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _iporOracle = IIporOracle(iporOracle);
        _asset = asset;
        _stanley = IStanley(stanley);
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

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
