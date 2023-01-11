// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

library JosephTypes {
    struct RedeemMoney {
        uint256 wadAssetAmount;
        uint256 redeemAmount;
        uint256 wadRedeemFee;
        uint256 wadRedeemAmount;
    }
}
