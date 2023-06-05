// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/types/CockpitTypes.sol";
import "../../libraries/Constants.sol";
import "../../interfaces/IIporOracle.sol";
import "../../interfaces/IAmmTreasury.sol";
import "../../interfaces/ICockpitDataProvider.sol";
import "../../security/IporOwnableUpgradeable.sol";

contract CockpitDataProvider is Initializable, UUPSUpgradeable, IporOwnableUpgradeable, ICockpitDataProvider {
    address internal _iporOracle;
    mapping(address => CockpitTypes.AssetConfig) internal _assetConfig;
    address[] internal _assets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address iporOracle,
        address[] memory assets,
        address[] memory ammTreasurys,
        address[] memory ipTokens,
        address[] memory ivTokens
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        uint256 assetsLength = assets.length;

        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        require(assetsLength == ammTreasurys.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);

        _iporOracle = iporOracle;
        _assets = assets;

        for (uint256 i; i != assetsLength; ) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ammTreasurys[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ipTokens[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ivTokens[i] != address(0), IporErrors.WRONG_ADDRESS);

            _assetConfig[assets[i]] = CockpitTypes.AssetConfig(ammTreasurys[i], ipTokens[i], ivTokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
    }

    function getIndexes() external view override returns (CockpitTypes.IporFront[] memory) {
        uint256 assetsLength = _assets.length;
        CockpitTypes.IporFront[] memory indexes = new CockpitTypes.IporFront[](assetsLength);

        for (uint256 i; i != assetsLength; ) {
            indexes[i] = _createIporFront(_assets[i]);
            unchecked {
                ++i;
            }
        }
        return indexes;
    }

    function getMyIpTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ipToken);
        return token.balanceOf(_msgSender());
    }

    function getMyIvTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ivToken);
        return token.balanceOf(_msgSender());
    }

    function getMyTotalSupply(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.balanceOf(_msgSender());
    }

    function getMyAllowanceInAmmTreasury(address asset) external view override returns (uint256) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        IERC20 token = IERC20(asset);
        return token.allowance(_msgSender(), config.ammTreasury);
    }

    function calculateSpread(address asset)
        external
        pure
        override
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        //        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        //        IAmmTreasury ammTreasury = IAmmTreasury(config.ammTreasury);

        //TODO: fix or remove from cockpit.
        //        try ammTreasury.calculateSpread() returns (int256 _spreadPayFixed, int256 _spreadReceiveFixed) {
        //            spreadPayFixed = _spreadPayFixed;
        //            spreadReceiveFixed = _spreadReceiveFixed;
        //        } catch {

        spreadPayFixed = 999999999999999999999;
        spreadReceiveFixed = 999999999999999999999;
        //        }
    }

    function _createIporFront(address asset) internal view returns (CockpitTypes.IporFront memory iporFront) {
        (uint256 value, uint256 ibtPrice, uint256 date) = IIporOracle(_iporOracle).getIndex(asset);

        iporFront = CockpitTypes.IporFront(IERC20MetadataUpgradeable(asset).symbol(), value, ibtPrice, 0, 0, date);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
