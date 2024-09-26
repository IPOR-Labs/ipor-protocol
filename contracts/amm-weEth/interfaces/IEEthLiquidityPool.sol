pragma solidity 0.8.26;

interface IEEthLiquidityPool {
    function deposit(address _referral) external payable returns (uint256);

    function getTotalEtherClaimOf(address _user) external view returns (uint256);
}
