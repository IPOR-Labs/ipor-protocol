// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;
import '../../contracts/amm/IporAmmV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract DerivativeLogicTest {

    function testCalculateInterest() public {
//        //given
//        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative();
//
//        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
//            30000000000000000,
//            100000000000000000000,
//            987030000000000000000, 40000000000000000,
//            0
//        );
//
//        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
//            20*1e18,
//            derivatives[i].fee.openingAmount,
//            derivatives[i].fee.iporPublicationAmount,
//            derivatives[i].fee.spreadPercentage
//        );
//        _derivatives[i] = DataTypes.IporDerivative(
//            derivatives[i].id,
//            derivatives[i].state,
//            derivatives[i].buyer,
//            derivatives[i].asset,
//            derivatives[i].direction,
//            derivatives[i].depositAmount,
//            fee,
//            derivatives[i].leverage,
//            derivatives[i].notionalAmount,
//            derivatives[i].startingTimestamp,
//            derivatives[i].endingTimestamp,
//            indicator
//        );
//
//
//        //when
//        DataTypes.IporDerivativeInterest derivativeInterest = DerivativeLogic.calculateInterest();

        //then

//        IporAmmV1 amm = IporAmmV1(DeployedAddresses.IporAmmV1());
//
//        uint expected = 0;
//
//        Assert.equal(amm.getTotalSupply("DAI"), expected, "Should be 10000");
    }

//    function testInitialBalanceWithNewMetaCoin() {
//        IporAmmV1 meta = new IporAmmV1();
//
//        uint expected = 10000;
//
//        Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
//    }
}