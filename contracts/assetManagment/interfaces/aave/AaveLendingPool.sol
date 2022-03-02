pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";

interface AaveLendingPool {
    function deposit(
        address reserve,
        uint256 amount,
        uint16 referralCode
    ) external;

    function getReserveData(address reserve)
        external
        view
        returns (DataTypes.ReserveData memory);
}
