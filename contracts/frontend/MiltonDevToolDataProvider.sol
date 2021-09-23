// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";

contract MiltonDevToolDataProvider is IMiltonDevToolDataProvider {

    IIporAddressesManager public immutable ADDRESSES_MANAGER;

    constructor(IIporAddressesManager addressesManager) {
        ADDRESSES_MANAGER = addressesManager;
    }

    function getMiltonTotalSupply(address asset) external override view returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.balanceOf(ADDRESSES_MANAGER.getMilton());
    }

    function getMyTotalSupply(address asset) external override view returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.balanceOf(msg.sender);
    }

    function getMyAllowance(address asset) external override view returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, ADDRESSES_MANAGER.getMilton());
    }

    function getPositions() external override view returns (DataTypes.IporDerivative[] memory) {
        return IMiltonStorage(ADDRESSES_MANAGER.getMiltonStorage()).getPositions();
    }

    function getMyPositions() external override view returns (DataTypes.IporDerivative[] memory items) {
        return IMiltonStorage(ADDRESSES_MANAGER.getMiltonStorage()).getUserPositions(msg.sender);
    }

    //@notice FOR TEST ONLY
    //    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
    //        return milton.getDerivatives().items[derivativeId].item;
    //    }
}