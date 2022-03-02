pragma solidity 0.8.9;
import "../interfaces/IPOR/IStrategy.sol";

// simple mock for total balance tests
contract StrategyMock is IStrategy {
    uint256 public balance;
    address public shareTokens;
    uint256 public apy;
    address public underlyingToken;
    address public owner;

    function deposit(uint256 amount) external {}

    function withdraw(uint256 amount) external {}

    function changeOwnership(address newOwner) external {
        owner = newOwner;
    }

    function getUnderlyingToken() external view returns (address) {
        return underlyingToken;
    }

    function setUnderlyingToken(address _underlyingToken) external {
        underlyingToken = _underlyingToken;
    }

    function getApy() external view returns (uint256) {
        return apy;
    }

    function setApy(uint256 _apy) public {
        apy = _apy;
    }

    function balanceOf() public view override returns (uint256) {
        return balance;
    }

    function setBalance(uint256 _balance) public {
        balance = _balance;
    }

    function shareToken() external view override returns (address) {
        return shareTokens;
    }

    function setShareToken(address _shareToken) public {
        shareTokens = _shareToken;
    }

    function doClaim(address vault, address[] memory assets)
        external
        payable
        override
    {}

    function transferOwnership(address newOwner) external {
        owner = newOwner;
    }

    function beforeClaim(address[] memory assets, uint256 _amount)
        external
        payable
    {}
}
