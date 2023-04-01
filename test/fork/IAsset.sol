pragma solidity 0.8.16;

interface IAsset {
    function approve(address _spender, uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}
