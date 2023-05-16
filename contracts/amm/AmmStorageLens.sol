// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IAmmStorageLens.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonSpreadModel.sol";

contract AmmStorageLens is IAmmStorageLens {
    address public immutable usdcAsset;
    address public immutable usdtAsset;
    address public immutable daiAsset;

    address public immutable usdcStorage;
    address public immutable usdtStorage;
    address public immutable daiStorage;

    IIporOracle public immutable iporOracle;

    constructor(
        address _usdcAsset,
        address _usdtAsset,
        address _daiAsset,
        address _usdcStorage,
        address _usdtStorage,
        address _daiStorage,
        IIporOracle _iporOracle
    ) {
        usdcAsset = _usdcAsset;
        usdtAsset = _usdtAsset;
        daiAsset = _daiAsset;
        usdcStorage = _usdcStorage;
        usdtStorage = _usdtStorage;
        daiStorage = _daiStorage;
        iporOracle = _iporOracle;
    }

    function calculateSpread(address asset)
        external
        view
        override
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
    }

    function _calculateSpread(address asset, uint256 calculateTimestamp)
    internal
    view
    returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        IporTypes.AccruedIpor memory accruedIpor = _iporOracle.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance(asset);

        IMiltonSpreadModel miltonSpreadModel = _miltonSpreadModel;

        spreadPayFixed = miltonSpreadModel.calculateSpreadPayFixed(accruedIpor, balance);
        spreadReceiveFixed = miltonSpreadModel.calculateSpreadReceiveFixed(accruedIpor, balance);
    }

    function getStorageImplementation(address asset) internal pure returns (address) {
        if (asset == usdcAsset) {
            return usdcStorage;
        } else if (asset == usdtAsset) {
            return usdtStorage;
        } else if (asset == daiAsset) {
            return daiStorage;
        } else {
            revert("Unsupported asset");
        }
    }
}
