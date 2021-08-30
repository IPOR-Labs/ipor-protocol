// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonAddressesManager.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";

contract MiltonDevToolDataProvider is IMiltonDevToolDataProvider {

    IMiltonAddressesManager public immutable ADDRESSES_MANAGER;

    constructor(IMiltonAddressesManager addressesManager) {
        ADDRESSES_MANAGER = addressesManager;
    }

    function getTokenAddress(string memory asset) external override view returns(address) {
        return ADDRESSES_MANAGER.getAddress(asset);
    }

    function getMiltonTotalSupply(string memory asset) external override view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(asset));
        return token.balanceOf(ADDRESSES_MANAGER.getMilton());
    }

    function getMyTotalSupply(string memory asset) external override view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(asset));
        return token.balanceOf(msg.sender);
    }

    function getMyAllowance(string memory asset) external override view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(asset));
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