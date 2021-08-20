// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonAddressesManager.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";

//dostarczyciel danych dla frontu
contract MiltonDevToolDataProvider is IMiltonDevToolDataProvider {

    IMiltonAddressesManager public immutable ADDRESSES_MANAGER;
    IMilton internal milton;

    constructor(IMiltonAddressesManager addressesManager) {
        ADDRESSES_MANAGER = addressesManager;
        milton = IMilton(addressesManager.getMilton());
    }

    //@notice FOR FRONTEND
    function getTotalSupply(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(DataTypes.stringToBytes32(asset)));
        return token.balanceOf(address(this));
    }
    //@notice FOR FRONTEND
    function getMyTotalSupply(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(DataTypes.stringToBytes32(asset)));
        return token.balanceOf(msg.sender);
    }
    //@notice FOR FRONTEND
    //TODO: use ERC20 directly
    function getMyAllowance(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(ADDRESSES_MANAGER.getAddress(DataTypes.stringToBytes32(asset)));
        return token.allowance(msg.sender, address(this));
    }

    //@notice FOR FRONTEND
    function getPositions() external view returns (DataTypes.IporDerivative[] memory) {
        //TODO: fix it, looks bad, DoS, possible out of gas
        return milton.getPositions();
    }

    //@notice FOR FRONTEND
    function getMyPositions() external view returns (DataTypes.IporDerivative[] memory items) {
        return milton.getUserPositions(msg.sender);
    }

    //@notice FOR TEST ONLY
    //    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
    //        return milton.getDerivatives().items[derivativeId].item;
    //    }
}