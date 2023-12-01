// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./mocks/tokens/MockTestnetToken.sol";
import "./mocks/tokens/MockTestnetToken.sol";
import "./utils/factory/IporProtocolFactory.sol";

contract TestCommons is Test {
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;
    address[] internal _users;
    uint constant PAY_FIXED = 0;
    uint constant RECEIVE_FIXED = 1;

    IporProtocolFactory internal _iporProtocolFactory = new IporProtocolFactory(address(this));

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _getStables() internal returns (MockTestnetToken dai, MockTestnetToken usdc, MockTestnetToken usdt) {
        dai = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        usdt = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
    }

    function usersToArray(
        address userOne,
        address userTwo,
        address userThree,
        address userFour,
        address userFive
    ) public pure returns (address[] memory) {
        address[] memory users = new address[](5);
        users[0] = userOne;
        users[1] = userTwo;
        users[2] = userThree;
        users[3] = userFour;
        users[4] = userFive;
        return users;
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

    function signRiskParams(
        AmmTypes.RiskIndicatorsInputs memory riskParamsInput,
        address asset,
        uint256 tenor,
        uint256 direction,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        // create digest: keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(
            abi.encodePacked(
                riskParamsInput.maxCollateralRatio,
                riskParamsInput.maxCollateralRatioPerLeg,
                riskParamsInput.maxLeveragePerLeg,
                riskParamsInput.baseSpreadPerLeg,
                riskParamsInput.fixedRateCapPerLeg,
                riskParamsInput.demandSpreadFactor,
                riskParamsInput.expiration,
                asset,
                tenor,
                direction
            )
        );
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }

    function getRiskIndicatorsInputs(
        address asset,
        uint direction
    ) internal returns (AmmTypes.RiskIndicatorsInputs memory) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            direction,
            _iporProtocolFactory.messageSignerPrivateKey()
        );
        return riskIndicatorsInputs;
    }

    function getCloseRiskIndicatorsInputs(
        address asset,
        IporTypes.SwapTenor tenor
    ) internal returns (AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInputs) {
        riskIndicatorsInputs.payFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.receiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.payFixed.signature = signRiskParams(
            riskIndicatorsInputs.payFixed,
            address(asset),
            uint256(tenor),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );
        riskIndicatorsInputs.receiveFixed.signature = signRiskParams(
            riskIndicatorsInputs.receiveFixed,
            address(asset),
            uint256(tenor),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );
    }

    function getIndexToUpdate(
        address asset,
        uint indexValue
    ) internal returns (IIporOracle.UpdateIndexParams[] memory) {
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](1);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: asset,
            indexValue: indexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        return updateIndexParams;
    }

    function getIndexToUpdateAndQuasiIbtPrice(
        address asset,
        uint indexValue,
        uint updateTimestamp,
        uint quasiIbtPrice
    ) internal returns (IIporOracle.UpdateIndexParams[] memory) {
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](1);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: asset,
            indexValue: indexValue,
            updateTimestamp: updateTimestamp,
            quasiIbtPrice: quasiIbtPrice
        });
        return updateIndexParams;
    }
}
