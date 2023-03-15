// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "./utils/TestConstants.sol";
import "../contracts/mocks/mockIporLogic.sol";

contract IporLogicTest is TestCommons, DataUtils {
	   
	MockIporLogic internal _iporLogic;
    
    function setUp() public {
		_iporLogic = new MockIporLogic();
    }

}
