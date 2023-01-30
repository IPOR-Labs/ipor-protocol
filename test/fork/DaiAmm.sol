// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../TestCommons.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "../../contracts/amm/Milton.sol";
import "./IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";


contract DaiAmm is Test, TestCommons {

    address  private constant _comptrollerAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address  private constant _compTokenAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address private constant _addressProviderAave = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address private constant _stkAave = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address private constant _aaveIncentiveAddress = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address private constant _aaveAddress = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public cDai = 0x5d3a536e4d6dbd6114cc1ead35777bab948e3643;
    address public aDai = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    StrategyCompound public strategyCompound;
    StrategyAave public strategyAave;

    constructor(address owner) {
        vm.startPrank(owner);
        _createCompoundStrategy();
        _createAaveStrategy();
        vm.stopPrank();
    }


    function _createCompoundStrategy() internal {
        StrategyCompound implementation = new StrategyCompound();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                dai,
                cDai,
                _comptrollerAddress,
                _compTokenAddress
            ));
        strategyCompound = StrategyCompound(address(proxy));
    }

    function _createAaveStrategy() internal {
        StrategyAave implementation = new StrategyAave();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                dai,
                aDai,
                _addressProviderAave,
                _stkAave,
                _aaveIncentiveAddress,
                _aaveAddress
            ));
        strategyAave = StrategyAave(address(proxy));
    }
}