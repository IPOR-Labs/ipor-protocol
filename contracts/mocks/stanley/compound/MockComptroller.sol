//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../vault/interfaces/compound/Comptroller.sol";

contract MockComptroller is Comptroller {
    address private _COMP;
    mapping(address => uint256) private _cTokens;
    uint256 internal _amount;

    constructor(
        address COMP,
        address cUSDT,
        address cUSDC,
        address cDAI
    ) public {
        _COMP = COMP;
        _cTokens[cUSDT] = 1;
        _cTokens[cUSDC] = 1;
        _cTokens[cDAI] = 1;
    }

    // This contract should have COMP inside
    function claimComp(
        address[] calldata,
        address[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external override {
        require(_cTokens[cTokens[0]] == 1, "Wrong cToken");
        require(!borrowers && suppliers, "Only suppliers should be true");
        IERC20(_COMP).transfer(
            msg.sender,
            _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount
        );
    }

    function claimComp(address _sender) external override {
        IERC20(_COMP).transfer(
            _sender,
            _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount
        );
    }

    //solhint-disable no-unused-vars
    function claimComp(address _sender, address[] memory assets) external {
        IERC20(_COMP).transfer(
            _sender,
            _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount
        );
    }

    function compSpeeds(address _cToken) external view override returns (uint256) {}
}
