// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISavingsDai {
    function balanceOf(address owner) external view returns (uint256);

    function pot() external view returns (address);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function maxDeposit(address) external pure returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address) external pure returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
