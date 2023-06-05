// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/types/IporOracleFacadeTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporOracleFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";

contract IporOracleFacadeDataProvider is
    Initializable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IIporOracleFacadeDataProvider
{
    address private _iporOracle;
    address[] internal _assets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory assets, address iporOracle) public initializer {
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        __Ownable_init();
        __UUPSUpgradeable_init();
        _iporOracle = iporOracle;
        _assets = assets;
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
    }

    function getIndexes() external view override returns (IporOracleFacadeTypes.IporFront[] memory) {
        uint256 assetLength = _assets.length;

        IporOracleFacadeTypes.IporFront[] memory indexes = new IporOracleFacadeTypes.IporFront[](assetLength);

        for (uint256 i; i != assetLength; ) {
            indexes[i] = _createIporFront(_assets[i]);
            unchecked {
                ++i;
            }
        }
        return indexes;
    }

    function _getIporOracle() internal view virtual returns (address) {
        return _iporOracle;
    }

    function _createIporFront(address asset) internal view returns (IporOracleFacadeTypes.IporFront memory iporFront) {
        (uint256 value, uint256 ibtPrice, uint256 date) = IIporOracle(_getIporOracle()).getIndex(asset);
        iporFront = IporOracleFacadeTypes.IporFront(
            IERC20MetadataUpgradeable(asset).symbol(),
            asset,
            value,
            ibtPrice,
            date
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
