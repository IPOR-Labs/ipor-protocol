pragma solidity 0.8.9;

//TODO: remove folder IPOR, not needed.
interface IStrategy {
    function getAsset() external view returns (address);

    function getApy() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function shareToken() external view returns (address);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function doClaim(address account, address[] calldata assets)
        external
        payable;

    function beforeClaim(address[] memory assets, uint256 amount)
        external
        payable;
}
