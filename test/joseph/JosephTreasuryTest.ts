import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    TC_TOTAL_AMOUNT_10_000_18DEC,
    PERCENTAGE_3_18DEC,
    USD_28_000_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    USD_10_18DEC,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareComplexTestDataDaiCase000,
    prepareComplexTestDataDaiCase400,
    getPayFixedDerivativeParamsDAICase1,
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

    it("should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer", async () => {
        //given
        const { josephDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            //when
            josephDai.connect(userThree).transferToCharlieTreasury(BigNumber.from("100")),
            //then
            "IPOR_406"
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - Charlie Treasury address incorrect", async () => {
        //given
        const { josephDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await josephDai.connect(admin).setCharlieTreasuryManager(await userThree.getAddress());

        //when
        await assertError(
            //when
            josephDai.connect(userThree).transferToCharlieTreasury(BigNumber.from("100")),
            //then
            "IPOR_407"
        );
    });

    it("should transfer Publication Fee to Charlie Treasury - simple case 1", async () => {
        //given
        const { josephDai, tokenDai, iporOracle, miltonDai, miltonStorageDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await josephDai.connect(admin).setCharlieTreasuryManager(await userThree.getAddress());

        await josephDai.connect(admin).setCharlieTreasury(await userOne.getAddress());

        const transferredAmount = BigNumber.from("100");

        //when
        await josephDai.connect(userThree).transferToCharlieTreasury(transferredAmount);

        //then
        const balance = await miltonStorageDai.getExtendedBalance();

        const expectedErc20BalanceCharlieTreasury = USER_SUPPLY_10MLN_18DEC.add(transferredAmount);
        const actualErc20BalanceCharlieTreasury = await tokenDai.balanceOf(
            await userOne.getAddress()
        );

        const expectedErc20BalanceMilton = USD_28_000_18DEC.add(TC_TOTAL_AMOUNT_10_000_18DEC).sub(
            transferredAmount
        );
        const actualErc20BalanceMilton = await tokenDai.balanceOf(miltonDai.address);

        const expectedPublicationFeeBalanceMilton = USD_10_18DEC.sub(transferredAmount);
        const actualPublicationFeeBalanceMilton = balance.iporPublicationFee;

        expect(
            expectedErc20BalanceCharlieTreasury,
            `Incorrect ERC20 Charlie Treasurer balance for ${params.asset}, actual:  ${actualErc20BalanceCharlieTreasury},
                expected: ${expectedErc20BalanceCharlieTreasury}`
        ).to.be.eq(actualErc20BalanceCharlieTreasury);

        expect(
            expectedErc20BalanceMilton,
            `Incorrect ERC20 Milton balance for ${params.asset}, actual:  ${actualErc20BalanceMilton},
                expected: ${expectedErc20BalanceMilton}`
        ).to.be.eq(actualErc20BalanceMilton);

        expect(
            expectedPublicationFeeBalanceMilton,
            `Incorrect Milton balance for ${params.asset}, actual:  ${actualPublicationFeeBalanceMilton},
                expected: ${expectedPublicationFeeBalanceMilton}`
        ).to.be.eq(actualPublicationFeeBalanceMilton);
    });

    it("should NOT transfer Treasure - caller not treasure transferer", async () => {
        //given
        const { josephDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            //when
            josephDai.connect(userThree).transferToTreasury(BigInt("100")),
            //then
            "IPOR_404"
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - Treasury Transferer address incorrect", async () => {
        //given
        const { josephDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await josephDai.connect(admin).setTreasuryManager(await userThree.getAddress());

        //when
        await assertError(
            //when
            josephDai.connect(userThree).transferToTreasury(BigInt("100")),
            //then
            "IPOR_405"
        );
    });

    it("should transfer Treasury to Treasury Treasurer - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase400(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, iporOracle, miltonDai, miltonStorageDai } = testData;

        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await josephDai.connect(admin).setTreasuryManager(await userThree.getAddress());

        await josephDai.connect(admin).setTreasury(await userOne.getAddress());

        const transferredAmount = BigNumber.from("100");

        //when
        await josephDai.connect(userThree).transferToTreasury(transferredAmount);

        //then
        const balance = await miltonStorageDai.getExtendedBalance();

        const expectedErc20BalanceTreasury = USER_SUPPLY_10MLN_18DEC.add(transferredAmount);
        const actualErc20BalanceTreasury = await tokenDai.balanceOf(await userOne.getAddress());

        const expectedErc20BalanceMilton = USD_28_000_18DEC.add(TC_TOTAL_AMOUNT_10_000_18DEC).sub(
            transferredAmount
        );
        const actualErc20BalanceMilton = await tokenDai.balanceOf(miltonDai.address);

        const expectedTreasuryBalanceMilton = BigNumber.from("149505148455463261");
        const actualTreasuryBalanceMilton = balance.treasury;

        expect(expectedErc20BalanceTreasury, `Incorrect ERC20 Treasury Treasurer balance`).to.be.eq(
            actualErc20BalanceTreasury
        );

        expect(expectedErc20BalanceMilton, `Incorrect ERC20 Milton balance`).to.be.eq(
            actualErc20BalanceMilton
        );

        expect(expectedTreasuryBalanceMilton, `Incorrect Treasury Balance in Milton`).to.be.eq(
            actualTreasuryBalanceMilton
        );
    });
});
