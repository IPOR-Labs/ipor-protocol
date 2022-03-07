pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./DataTypesContract.sol";

interface AaveLendingPoolV2 {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function getReserveData(address asset)
        external
        view
        returns (DataTypesContract.ReserveData memory);
}
