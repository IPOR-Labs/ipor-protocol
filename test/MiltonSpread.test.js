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

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance > 0 ", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee > 0, pay fixed derivative balance = 0", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = testUtils.ZERO;
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1650549450549451");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Pay Fixed Derivative, imbalance factor > 0, opening fee = 0, pay fixed derivative balance = 0", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.ZERO;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = testUtils.ZERO;
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1648351648351648");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentPayFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    // it("should NOT calculate spread - demand component - Pay Fixed Derivative, Adjusted Utilization Rate equal 1, demand component with denominator equal 0 ", async () => {
    //     //TODO: implement it
    // });

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance > RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance = RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("5000000000000000000000");
        const recFixedDerivativesBalance = BigInt("5000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1001333333333333");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, PayFix Balance < RecFix Balance", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = testUtils.USD_10_000_18DEC;
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("3000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1155384615384615");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, 100% utilization rate including position ", async () => {
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
        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = testUtils.USD_20_18DEC;

        const expectedSpreadDemandComponentValue = BigInt("1000000000000000");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance > 0 ", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = BigInt("1000000000000000000000");

        const expectedSpreadDemandComponentValue = BigInt("1444230769230769");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee > 0, rec fixed derivative balance = 0", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.USD_20_18DEC;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = testUtils.ZERO;

        const expectedSpreadDemandComponentValue = BigInt("1650549450549451");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    it("should calculate spread - demand component - Rec Fixed Derivative, imbalance factor > 0, opening fee = 0, rec fixed derivative balance = 0", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );

        const asset = await testData.tokenDai.address;
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = testUtils.ZERO;
        const liquidityPool = BigInt("15000000000000000000000");
        const payFixedDerivativesBalance = BigInt("13000000000000000000000");
        const recFixedDerivativesBalance = testUtils.ZERO;

        const expectedSpreadDemandComponentValue = BigInt("1648351648351648");

        //when
        let actualSpreadDemandComponentValue = BigInt(
            await testData.miltonSpread.calculateDemandComponentRecFixed.call(
                asset,
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
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

    // it("should NOT calculate spread - demand component - Rec Fixed Derivative, Adjusted Utilization Rate equal 1, demand component with denominator equal 0 ", async () => {
    //     //TODO: implement it
    // });
});
