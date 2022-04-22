import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <table className="table" align="center">
            <tr>
                <td>
                    <strong>IporOracle</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.IporOracle.address}
                </td>
            </tr>

            <tr>
                <td>
                    <strong>ItfIporOracle</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfIporOracle.address
                        : "NONE"}
                </td>
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfMilton</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonDai.address
                        : "NONE"}
                </td>
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfJoseph</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephDai.address
                        : "NONE"}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Stanley</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfStanley</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyDai.address
                        : "NONE"}
                </td>
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
