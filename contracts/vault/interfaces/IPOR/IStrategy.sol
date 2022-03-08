pragma solidity 0.8.9;

//TODO: remove folder IPOR, not needed.
interface IStrategy {
    function getAsset() external view returns (address);

    function getShareToken() external view returns (address);

    function getApy() external view returns (uint256);

    //@notice return amount of asset token (stable tokens)
    function balanceOf() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function beforeClaim() external;

    function doClaim() external;

    function setStanley(address stanley) external;

    function setTreasury(address treasury) external;

    event SetStanley(address sender, address newStanley, address strategy);
    // TODO: ADD test for events into fork test
    event DoClaim(address strategy, address[] assets, address claimAddress, uint256 amount);

    event DoBeforeClaim(address strategy, address[] assets);

    event SetTreasury(address strategy, address newTreasury);
}
