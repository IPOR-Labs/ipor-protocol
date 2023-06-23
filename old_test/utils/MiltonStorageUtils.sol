// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../utils/TestConstants.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/interfaces/types/AmmTypes.sol";

contract AmmStorageUtils is Test {
    struct AmmStorages {
        AmmStorage ammStorageUsdt;
        AmmStorage ammStorageUsdc;
        AmmStorage ammStorageDai;
    }

    function getAmmStorage() public returns (AmmStorage) {
        AmmStorage ammStorageImplementation = new AmmStorage();
        ERC1967Proxy ammStorageProxy = new ERC1967Proxy(
            address(ammStorageImplementation),
            abi.encodeWithSignature("initialize()", "")
        );
        return AmmStorage(address(ammStorageProxy));
    }

    function prepareSwapPayFixedStruct18DecSimpleCase1(address buyer) public view returns (AmmTypes.NewSwap memory) {
        AmmTypes.NewSwap memory newSwap;
        newSwap.buyer = buyer;
        newSwap.openTimestamp = block.timestamp;
        newSwap.collateral = TestConstants.USD_1_000_18DEC;
        newSwap.notional = TestConstants.USD_5_000_18DEC;
        newSwap.ibtQuantity = 123;
        newSwap.fixedInterestRate = 234;
        newSwap.liquidationDepositAmount = 20;
        newSwap.openingFeeLPAmount = TestConstants.USD_1_500_18DEC;
        newSwap.openingFeeTreasuryAmount = TestConstants.USD_1_500_18DEC;
        return newSwap;
    }
}
