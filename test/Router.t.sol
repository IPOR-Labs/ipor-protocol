// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestCommons.sol";

contract RouterTest is TestCommons {
    function testSwitchImplementation() public {
        // given
        IporProtocolRouterBuilder builder = new IporProtocolRouterBuilder(address(this));
        IporProtocolRouter router = builder.buildEmptyProxy();

        address newImplementation = address(new EmptyRouterImplementation());
        address oldImplementation = router.getImplementation();
        // when
        router.upgradeTo(newImplementation);

        // then
        assertTrue(router.getImplementation() == newImplementation, "Implementation should be equal to newImplementation");
        assertTrue(router.getImplementation() != oldImplementation, "Implementation should be changed");
    }
}
