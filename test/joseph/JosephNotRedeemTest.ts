import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { PERCENTAGE_3_18DEC, N1__0_18DEC } from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareTestDataDaiCase000,
    prepareTestDataDaiCase001,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    getStandardDerivativeParamsDAI,
	getReceiveFixedSwapParamsDAI
} from "../utils/DataUtils";

const { expect } = chai;

describe("Joseph Treasury", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization already exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } =
            testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigNumber.from("60000").mul(N1__0_18DEC);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(ipTokenAmount, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("45000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        const balance = await miltonDai.getAccruedBalance();
        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = balance.liquidityPool;

        await assertError(
            //when
            josephDai.connect(liquidityProvider).itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );

        //then
        expect(
            actualCollateral.gt(actualLiquidityPoolBalance),
            "Actual collateral cannot be lower than actual Liquidity Pool Balance"
        ).to.be.true;
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization already exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } =
            testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigNumber.from("60000").mul(N1__0_18DEC);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(ipTokenAmount, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());

        await miltonStorageDai.subtractLiquidity(BigNumber.from("45000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        const balance = await miltonDai.getAccruedBalance();
        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = BigNumber.from(balance.liquidityPool);

        await assertError(
            //when
            josephDai.connect(liquidityProvider).itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );

        //then
        expect(
            actualCollateral.gt(actualLiquidityPoolBalance),
            "Actual collateral cannot be lower than actual Liquidity Pool Balance"
        ).to.be.true;
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization exceeded, Pay Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigNumber.from("41000").mul(N1__0_18DEC);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const balance = await miltonDai.getAccruedBalance();

        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = balance.liquidityPool;

        await assertError(
            //when
            josephDai.connect(liquidityProvider).itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
        expect(
            actualCollateral.lt(actualLiquidityPoolBalance),
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );
    });

    it("should NOT redeem - Redeem Liquidity Pool Utilization exceeded, Receive Fixed", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, iporOracle } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const ipTokenAmount = BigNumber.from("41000").mul(N1__0_18DEC);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        const balance = await miltonDai.getAccruedBalance();

        const actualCollateral = balance.totalCollateralPayFixed.add(
            balance.totalCollateralReceiveFixed
        );
        const actualLiquidityPoolBalance = BigNumber.from(balance.liquidityPool);

        await assertError(
            //when
            josephDai.connect(liquidityProvider).itfRedeem(ipTokenAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
        expect(
            actualCollateral.lt(actualLiquidityPoolBalance),
            "Actual collateral cannot be higher than actual Liquidity Pool Balance"
        );
    });

    it("should NOT redeem ipTokens because of empty Liquidity Pool", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai, miltonStorageDai } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await miltonStorageDai.setJoseph(await userOne.getAddress());
        await miltonStorageDai.connect(userOne).subtractLiquidity(params.totalAmount);
        await miltonStorageDai.setJoseph(josephDai.address);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfRedeem(BigNumber.from("1000").mul(N1__0_18DEC), params.openTimestamp),
            //then
            "IPOR_300"
        );
    });

    it("should NOT redeem ipTokens because after redeem Liquidity Pool will be empty", async () => {
        //given
        const testData = await prepareTestDataDaiCase001(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { josephDai, ipTokenDai, tokenDai, miltonDai } = testData;
        if (
            josephDai === undefined ||
            ipTokenDai === undefined ||
            tokenDai == undefined ||
            miltonDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(params.totalAmount, params.openTimestamp);

        //when
        await assertError(
            //when
            josephDai
                .connect(liquidityProvider)
                .itfRedeem(params.totalAmount, params.openTimestamp),
            //then
            "IPOR_402"
        );
    });
});
