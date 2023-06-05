// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;
import "./MockCaseBaseAssetManagement.sol";

contract MockCase2AssetManagement is MockCaseBaseAssetManagement {

    //@dev withdraw 80%
    function _withdrawRate() internal pure override returns (uint256) {
        return 8e17;
    }
}
