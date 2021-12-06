const keccak256 = require("keccak256");
const testUtils = require("./TestUtils.js");
const { ZERO } = require("./TestUtils");

contract("MiltonSpread", (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, userFive, _] =
        accounts;

    let data = null;

    before(async () => {
        data = await testUtils.prepareData(admin);
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance > RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("2000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const multiplicator = BigInt("1000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("83335000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                multiplicator,
                { from: liquidityProvider }
            )
        );

        //then

        assert(
            expectedSpreadDemandComponentValue ===
                actualSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        );
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance = RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const multiplicator = BigInt("1000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("90910909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                multiplicator,
                { from: liquidityProvider }
            )
        );

        //then

        assert(
            expectedSpreadDemandComponentValue ===
                actualSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        );
    });

    it("should calculate spread - demand component - Pay Fixed Derivative, PayFix Balance < RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("2000000000000000000000");
        const multiplicator = BigInt("1000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("90910909090909091");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                multiplicator,
                { from: liquidityProvider }
            )
        );

        //then

        assert(
            expectedSpreadDemandComponentValue ===
                actualSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        );
    });

	// it("should NOT calculate spread - demand component - Pay Fixed Derivative - opening fee is zero", async () => {
    //     //given
    //     let testData = await testUtils.prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data
    //     );

    //     const asset = await testData.tokenDai.address;
    //     const derivativeDeposit = BigInt("10000000000000000000");
    //     const derivativeOpeningFee = testUtils.USD_20_18DEC;
    //     const liquidityPool = testUtils.ZERO;
    //     const payFixedDerivativesBalance = testUtils.ZERO;
    //     const recFixedDerivativesBalance = BigInt("1000000000000000000000");
    //     const multiplicator = BigInt("1000000000000000000");

    //     const expectedSpreadDemandComponentValue = BigInt("1");

    //     //when
    //     let actualSpreadDemandComponentValue = BigInt(
    //         await testData.miltonSpread.calculateDemandComponentPayFixed.call(
    //             asset,
    //             derivativeDeposit,
    //             derivativeOpeningFee,
    //             liquidityPool,
    //             payFixedDerivativesBalance,
    //             recFixedDerivativesBalance,
    //             multiplicator,
    //             { from: liquidityProvider }
    //         )
    //     );

    //     //then

    //     assert(
    //         expectedSpreadDemandComponentValue ===
    //             actualSpreadDemandComponentValue,
    //         `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
    //     );
    // });

    it("should calculate spread - demand component - Pay Fixed Derivative, 100% utilization rate including position ", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("1000000000000000000000");
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("1000000000000000000000");
        const payFixedDerivativesBalance = testUtils.USD_20_18DEC;
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");
        const multiplicator = BigInt("1000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1000000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                multiplicator,
                { from: liquidityProvider }
            )
        );

        //then
        assert(
            expectedSpreadDemandComponentValue ===
                actualSpreadDemandComponentValue,
            `Incorrect spread demand component value actual: ${actualSpreadDemandComponentValue}, expected: ${expectedSpreadDemandComponentValue}`
        );
    });
});
