pragma solidity 0.8.26;

interface IUSDM {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}