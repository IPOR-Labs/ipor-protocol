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
        </table>
    </div>
);
