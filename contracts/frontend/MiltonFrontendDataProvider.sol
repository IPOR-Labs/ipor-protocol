// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IMiltonStorage.sol";

//TODO: consult with frontend developer and prepare appropriate methods and structure dedicated for frontend website, here is place for it
contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {

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
        //TODO: fix it, looks bad, DoS, possible out of gas
        return IMiltonStorage(ADDRESSES_MANAGER.getMiltonStorage()).getPositions();
    }

    function getMyPositions() external override view returns (DataTypes.IporDerivative[] memory items) {
        return IMiltonStorage(ADDRESSES_MANAGER.getMiltonStorage()).getUserPositions(msg.sender);
    }
}