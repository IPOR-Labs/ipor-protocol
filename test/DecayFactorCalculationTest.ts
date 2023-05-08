import hre from "hardhat";
import chai from "chai";
import { BigNumber } from "ethers";
import { MockDecayFactorCalculation } from "../types";
const { expect } = chai;
import linearFunctionTestData from "./asset/testDataForLinearFunctionHardhat.json";
const itParam = require("mocha-param");

type LinearFunctionTestItem = {
    slope: string;
    base: string;
    variable: string;
    result: string;
};

describe("#AmMath division", () => {
    let decayFactorCalculation: MockDecayFactorCalculation;

    before(async () => {
        const MockDecayFactorCalculationFactory = await hre.ethers.getContractFactory(
            "MockDecayFactorCalculation"
        );
        decayFactorCalculation =
            (await MockDecayFactorCalculationFactory.deploy()) as MockDecayFactorCalculation;
    });
    itParam(
        "Should evealuate value of linear function",
        linearFunctionTestData.data,
        async (item: LinearFunctionTestItem) => {
            // given
            const slope = BigNumber.from(item.slope);
            const base = BigNumber.from(item.base);
            const variable = BigNumber.from(item.variable);
            const result = BigNumber.from(item.result);
            //when
            const resultFromContract = await decayFactorCalculation.linearFunction(
                slope,
                base,
                variable
            );
            // then
            expect(resultFromContract, `${slope} * ${variable} + ${base} = ${result}`).to.be.equal(
                result
            );
        }
    );
});
