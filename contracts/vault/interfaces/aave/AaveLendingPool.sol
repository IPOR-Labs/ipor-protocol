pragma solidity 0.8.9;

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
