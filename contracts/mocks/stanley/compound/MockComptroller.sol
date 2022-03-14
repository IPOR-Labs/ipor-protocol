// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../vault/interfaces/compound/Comptroller.sol";

contract MockComptroller is Comptroller {
    address private _compAddr;
    address private _cTokenAddr;
    uint256 private _amount;

    constructor(address comp, address cToken) public {
        _compAddr = comp;
        _cTokenAddr = cToken;
    }

    function setAmount(uint256 amount) external {
        _amount = amount;
    }

    // This contract should have COMP inside
    function claimComp(
        address[] calldata,
        address[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external override {
        require(_cTokenAddr == cTokens[0], "Wrong cToken");
        require(!borrowers && suppliers, "Only suppliers should be true");
        IERC20(_compAddr).transfer(
            msg.sender,
            _amount > IERC20(_compAddr).balanceOf(address(this)) ? 0 : _amount
        );
    }

    function claimComp(address _sender) external override {
        IERC20(_compAddr).transfer(
            _sender,
            _amount > IERC20(_compAddr).balanceOf(address(this)) ? 0 : _amount
        );
    }

    function claimComp(address _sender, address[] memory assets) external {
        IERC20(_compAddr).transfer(
            _sender,
            _amount > IERC20(_compAddr).balanceOf(address(this)) ? 0 : _amount
        );
    }

    function compSpeeds(address _cToken) external view override returns (uint256) {}
}
