pragma solidity 0.8.16;

interface IAsset {
    function approve(address _spender, uint _value) external;
    function balanceOf(address account) external view returns (uint256);
}