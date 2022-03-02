pragma solidity 0.8.9;
import "../interfaces/IPOR/IStrategy.sol";

// simple mock for total _balance tests
contract StrategyMock is IStrategy {
    uint256 private _balance;
    address private _shareTokens;
    uint256 private _apy;
    address private _underlyingToken;
    address private _owner;

    function deposit(uint256 amount) external {}

    function withdraw(uint256 amount) external {}

    function changeOwnership(address newOwner) external {
        _owner = newOwner;
    }

    function getUnderlyingToken() external view returns (address) {
        return _underlyingToken;
    }

    function setUnderlyingToken(address underlyingToken) external {
        _underlyingToken = underlyingToken;
    }

    function getApy() external view returns (uint256) {
        return _apy;
    }

    function setApy(uint256 apy) external {
        _apy = apy;
    }

    function balanceOf() external view returns (uint256) {
        return _balance;
    }

    function setBalance(uint256 balance) external {
        _balance = balance;
    }

    function shareToken() external view override returns (address) {
        return _shareTokens;
    }

    function setShareToken(address shareToken) external {
        _shareTokens = shareToken;
    }

    function doClaim(address vault, address[] memory assets)
        external
        payable
        override
    {}

    function transferOwnership(address newOwner) external {
        _owner = newOwner;
    }

    function beforeClaim(address[] memory assets, uint256 amount)
        external
        payable
    {}
}
