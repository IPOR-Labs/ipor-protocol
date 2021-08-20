// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IMiltonFrontendDataProvider.sol";
import "../interfaces/IMiltonAddressesManager.sol";
import "../interfaces/IMilton.sol";

//dostarczyciel danych dla frontu
contract MiltonFrontendDataProvider is IMiltonFrontendDataProvider {

    IMiltonAddressesManager public immutable ADDRESSES_MANAGER;
    IMilton internal milton;

    constructor(IMiltonAddressesManager addressesManager) {
        ADDRESSES_MANAGER = addressesManager;
        milton = IMilton(addressesManager.getMilton());
    }
}