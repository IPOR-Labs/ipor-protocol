// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../../test/TestCommons.sol";
import "../../contracts/amm/spread/Spread28Days.sol";
import "../../contracts/amm/spread/Spread60Days.sol";
import "../../contracts/amm/spread/Spread90Days.sol";
import "../../contracts/amm/spread/SpreadStorageLens.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "../../contracts/amm/spread/SpreadCloseSwapService.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/amm/spread/SpreadStorageService.sol";

contract SpreadTestSystem is TestCommons {
    address public owner;
    MockTestnetToken public dai;
    MockTestnetToken public usdc;
    MockTestnetToken public usdt;
    Spread28Days public spread28Days;
    Spread60Days public spread60Days;
    Spread90Days public spread90Days;
    SpreadStorageLens public spreadStorageLens;
    SpreadCloseSwapService public spreadCloseSwapService;
    SpreadStorageService public spreadStorageService;
    address public router;
    address public ammStorage;

    constructor(address ammAddress) {
        (dai, usdc, usdt) = _getStables();
        owner = _getUserAddress(100);
        vm.startPrank(owner);
        spread28Days = new Spread28Days(address(dai), address(usdc), address(usdt));
        spread60Days = new Spread60Days(address(dai), address(usdc), address(usdt));
        spread90Days = new Spread90Days(address(dai), address(usdc), address(usdt));
        spreadCloseSwapService = new SpreadCloseSwapService(address(dai), address(usdc), address(usdt));
        spreadStorageLens = new SpreadStorageLens();
        spreadStorageService = new SpreadStorageService();
        SpreadRouter routerImplementation = new SpreadRouter(
            SpreadRouter.DeployedContracts(
                ammAddress,
                address(spread28Days),
                address(spread60Days),
                address(spread90Days),
                address(spreadStorageLens),
                address(spreadCloseSwapService),
                address(spreadStorageService)
            )
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(routerImplementation),
            abi.encodeWithSignature("initialize(bool)", false)
        );
        router = address(proxy);

        AmmStorage storageImplementation = new AmmStorage(owner, owner);
        ERC1967Proxy storageProxy = new ERC1967Proxy(
            address(storageImplementation),
            abi.encodeWithSignature("initialize()", "")
        );
        ammStorage = address(storageProxy);
        vm.stopPrank();
    }

    function mintStables(address account, uint256 amount) external {
        vm.startPrank(owner);
        dai.mint(account, amount * 1e18);
        usdc.mint(account, amount * 1e6);
        usdt.mint(account, amount * 1e6);
        vm.stopPrank();
    }
}
