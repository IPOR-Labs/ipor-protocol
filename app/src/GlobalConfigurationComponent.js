import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <table className="table" align="center">
            <tr>
                <td>
                    <strong>Warren</strong>
                </td>
                <td>{drizzle.contracts.Warren.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfWarren</strong>
                </td>
                <td>{drizzle.contracts.ItfWarren.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Milton Spread Model</strong>
                </td>
                <td>{drizzle.contracts.MiltonSpreadModel.address}</td>
            </tr>
        </table>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>
                    <strong>Milton</strong>
                </td>
                <td>{drizzle.contracts.MiltonUsdt.address}</td>
                <td>{drizzle.contracts.MiltonUsdc.address}</td>
                <td>{drizzle.contracts.MiltonDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfMilton</strong>
                </td>
                <td>{drizzle.contracts.ItfMiltonUsdt.address}</td>
                <td>{drizzle.contracts.ItfMiltonUsdc.address}</td>
                <td>{drizzle.contracts.ItfMiltonDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Milton Storage</strong>
                </td>
                <td>{drizzle.contracts.MiltonStorageUsdt.address}</td>
                <td>{drizzle.contracts.MiltonStorageUsdc.address}</td>
                <td>{drizzle.contracts.MiltonStorageDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Joseph</strong>
                </td>
                <td>{drizzle.contracts.JosephUsdt.address}</td>
                <td>{drizzle.contracts.JosephUsdc.address}</td>
                <td>{drizzle.contracts.JosephDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfJoseph</strong>
                </td>
                <td>{drizzle.contracts.ItfJosephUsdt.address}</td>
                <td>{drizzle.contracts.ItfJosephUsdc.address}</td>
                <td>{drizzle.contracts.ItfJosephDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Stanley</strong>
                </td>
                <td>{drizzle.contracts.StanleyUsdt.address}</td>
                <td>{drizzle.contracts.StanleyUsdc.address}</td>
                <td>{drizzle.contracts.StanleyDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfStanley</strong>
                </td>
                <td>{drizzle.contracts.ItfStanleyUsdt.address}</td>
                <td>{drizzle.contracts.ItfStanleyUsdc.address}</td>
                <td>{drizzle.contracts.ItfStanleyDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>IpToken</strong>
                </td>
                <td>{drizzle.contracts.IpTokenUsdt.address}</td>
                <td>{drizzle.contracts.IpTokenUsdc.address}</td>
                <td>{drizzle.contracts.IpTokenDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>IvToken</strong>
                </td>
                <td>{drizzle.contracts.IvTokenUsdt.address}</td>
                <td>{drizzle.contracts.IvTokenUsdc.address}</td>
                <td>{drizzle.contracts.IvTokenDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>aToken (Aave Share Token)</strong>
                </td>
                <td>{drizzle.contracts.MockAUsdt.address}</td>
                <td>{drizzle.contracts.MockAUsdc.address}</td>
                <td>{drizzle.contracts.MockADai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>cToken (Compound Share Token)</strong>
                </td>
                <td>{drizzle.contracts.MockCUSDT.address}</td>
                <td>{drizzle.contracts.MockCUSDC.address}</td>
                <td>{drizzle.contracts.MockCDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Aave Strategy</strong>
                </td>
                <td>{drizzle.contracts.StrategyAaveUsdt.address}</td>
                <td>{drizzle.contracts.StrategyAaveUsdc.address}</td>
                <td>{drizzle.contracts.StrategyAaveDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Compound Strategy</strong>
                </td>
                <td>{drizzle.contracts.StrategyCompoundUsdt.address}</td>
                <td>{drizzle.contracts.StrategyCompoundUsdc.address}</td>
                <td>{drizzle.contracts.StrategyCompoundDai.address}</td>
            </tr>
        </table>
    </div>
);
