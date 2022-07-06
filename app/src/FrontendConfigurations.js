import React from "react";
// import { Link } from "react-router-dom";

export default (configurations) =>
    configurations && configurations.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                    <tr>
                        <th scope="col">Asset</th>
                        <th scope="col">Min Leverage Value</th>
                        <th scope="col">Max Leverage Value</th>
                        <th scope="col">Opening Fee Rate</th>
                        <th scope="col">IPOR Publication Fee Amount</th>
                        <th scope="col">Liquidation Deposit Amount</th>
                        <th scope="col">Income Fee Rate</th>
                        <th scope="col">Max Liquidity Pool Utilization Rate</th>
                        <th scope="col">Max Liquidity Pool Utilization Per Leg Rate</th>
                        <th scope="col">Max Liquidity Pool Amount</th>
                        <th scope="col">Max Liquidity Pool Account Contribution Amount</th>
                    </tr>
                </thead>
                <tbody>
                    {configurations.map((configuration) => {
                        return (
                            <tr key={configuration.asset}>
                                <td>{configuration.asset}</td>
                                <td>
                                    {configuration.minLeverage / 1000000000000000000}
                                    <br />
                                    <small>{configuration.minLeverage}</small>
                                </td>
                                <td>
                                    {configuration.maxLeverage / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLeverage}</small>
                                </td>
                                <td>
                                    {configuration.openingFeeRate / 1000000000000000000}
                                    <br />
                                    <small>{configuration.openingFeeRate}</small>
                                </td>
                                <td>
                                    {configuration.iporPublicationFeeAmount / 1000000000000000000}
                                    <br />
                                    <small>{configuration.iporPublicationFeeAmount}</small>
                                </td>
                                <td>
                                    {configuration.liquidationDepositAmount / 1000000000000000000}
                                    <br />
                                    <small>{configuration.liquidationDepositAmount}</small>
                                </td>
                                <td>
                                    {configuration.incomeFeeRate / 1000000000000000000}
                                    <br />
                                    <small>{configuration.incomeFeeRate}</small>
                                </td>
                                <td>
                                    {configuration.maxLpUtilizationRate / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLpUtilizationRate}</small>
                                </td>
                                <td>
                                    {configuration.maxLpUtilizationPerLegRate / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLpUtilizationPerLegRate}</small>
                                </td>
                                <td>
                                    {configuration.maxLiquidityPoolAmount / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLiquidityPoolAmount}</small>
                                </td>
                                <td>
                                    {configuration.maxLpAccountContributionAmount /
                                        1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLpAccountContributionAmount}</small>
                                </td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    ) : (
        <p>No configuration set</p>
    );
