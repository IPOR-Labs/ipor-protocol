pragma solidity 0.8.9;

//TODO: remove folder IPOR, not needed.
interface IStrategy {
    function balanceOf() external view returns (uint256);

    function beforeClaim(address[] memory assets, uint256 _amount)
        external
        payable;

    function deposit(uint256 amount) external;

    function doClaim(address account, address[] calldata assets)
        external
        payable;

    function getApy() external view returns (uint256);

    function getAsset() external view returns (address);

    function setStanley(address stanley) external;

    function shareToken() external view returns (address);

    function withdraw(uint256 amount) external;

    event SetStanley(address sender, address newStanley, address strategy);
}
