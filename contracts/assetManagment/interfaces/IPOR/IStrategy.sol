pragma solidity 0.8.9;

interface IStrategy {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    // TODO: remove this method and use IporOwnableUpgradeable
    function changeOwnership(address newOwner) external;

    function getAsset() external view returns (address);

    function getApy() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function shareToken() external view returns (address);

    function doClaim(address account, address[] calldata assets)
        external
        payable;

    function beforeClaim(address[] memory assets, uint256 _amount)
        external
        payable;
}
