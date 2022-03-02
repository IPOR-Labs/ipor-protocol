pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";

interface AaveLendingPool {
  function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
  function getReserveData(address _reserve) external view returns (DataTypes.ReserveData memory);
}
