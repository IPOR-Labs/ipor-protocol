// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library DataTypes {

    //@notice IPOR Index structure
    struct IporIndex {
        string ticker;
        uint256 value;
        uint256 interestBearingToken;
        uint256 date;
    }
}