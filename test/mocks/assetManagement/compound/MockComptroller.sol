//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";
import "@ipor-protocol/contracts/vault/interfaces/compound/Comptroller.sol";

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
        require(COMP != address(0), string.concat(IporErrors.WRONG_ADDRESS, " COMP asset address cannot be 0"));
        require(cUSDT != address(0), string.concat(IporErrors.WRONG_ADDRESS, " cUSDT asset address cannot be 0"));
        require(cUSDC != address(0), string.concat(IporErrors.WRONG_ADDRESS, " cUSDC asset address cannot be 0"));
        require(cDAI != address(0), string.concat(IporErrors.WRONG_ADDRESS, " cDAI asset address cannot be 0"));

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
        IERC20(_COMP).transfer(msg.sender, _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount);
    }

    function claimComp(address _sender) external override {
        IERC20(_COMP).transfer(_sender, _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount);
    }

    //solhint-disable no-unused-vars
    function claimComp(address _sender, address[] memory assets) external {
        require(assets.length > 0);
        IERC20(_COMP).transfer(_sender, _amount > IERC20(_COMP).balanceOf(address(this)) ? 0 : _amount);
    }

    function compSpeeds(address _cToken) external view override returns (uint256) {}
}
