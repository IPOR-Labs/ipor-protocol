// To run this script
// truffle exec scripts/mock-asset-management.js --network <nameOfNetwork>
// truffle exec scripts/mock-asset-management.js --network docker

const { BigNumber } = require("ethers");

const DaiMockedToken = artifacts.require("DaiMockedToken.sol");
const UsdcMockedToken = artifacts.require("UsdcMockedToken.sol");
const UsdtMockedToken = artifacts.require("UsdtMockedToken.sol");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt.sol");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc.sol");
const MiltonStorageDai = artifacts.require("MiltonStorageDai.sol");

const IporOracle = artifacts.require("IporOracle");
const one = "1000000000000000000";

const delay = (time) => {
    return new Promise((resolve) => setTimeout(resolve, time));
};

const calculate = async (milton, asset, iporOracle, zeroNight, timeDeltaPerYear) => {
    const { totalCollateralPayFixed, totalCollateralReceiveFixed, liquidityPool } =
        await milton.getBalance();
    const total = BigNumber.from(liquidityPool)
        .add(BigNumber.from(totalCollateralReceiveFixed))
        .add(BigNumber.from(totalCollateralPayFixed));
    const { indexValue } = await iporOracle.getIndex(asset.address);
    return BigNumber.from(indexValue.toString())
        .mul(total)
        .div(one)
        .mul(zeroNight)
        .div(one)
        .mul(timeDeltaPerYear)
        .div(one);
};

console.log("start");

module.exports = async (done) => {
    const daiToken = await DaiMockedToken.deployed();
    const usdtToken = await UsdtMockedToken.deployed();
    const usdcToken = await UsdcMockedToken.deployed();
    const miltonStorageUsdt = await MiltonStorageUsdt.deployed();
    const miltonStorageUsdc = await MiltonStorageUsdc.deployed();
    const miltonStorageDai = await MiltonStorageDai.deployed();
    const iporOracle = await IporOracle.deployed();

    const data = [
        { milton: miltonStorageUsdt, asset: usdtToken },
        { milton: miltonStorageUsdc, asset: usdcToken },
        { milton: miltonStorageDai, asset: daiToken },
    ];

    const zeroNight = BigNumber.from("900000000000000000"); // 0.9*10^18
    const timeDeltaPerYear = BigNumber.from("9512937595129"); // 5min ->  (5/(60*24*365))10^18

    while (true) {
        for (let i = 0; i < data.length; i++) {
            const result = await calculate(
                data[i].milton,
                data[i].asset,
                iporOracle,
                zeroNight,
                timeDeltaPerYear
            );
            console.log("Result to save: ", result.toString());
            await data[i].milton.addLiquidityAssetManagmentMock(result);
            // used to add initial value of liquidyty
            // await data[i].milton.addLiquidityAssetManagmentMock(
            //     BigNumber.from("5000000000000000000")
            // );
        }
        await delay(1000 * 60 * 5); //1s * 60 * 5 = 5minutes
    }
    done();
};
