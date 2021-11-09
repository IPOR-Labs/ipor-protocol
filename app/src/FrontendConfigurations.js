import React from "react";
// import { Link } from "react-router-dom";

export default (configurations) => (
    configurations && configurations.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                <tr>
                    <th scope="col">Asset</th>
                    <th scope="col">Min Collateralization Factor Value</th>
                    <th scope="col">Max Collateralization Factor Value</th>
                    <th scope="col">Opening Fee Percentage</th>
                    <th scope="col">IPOR Publication Fee Amount</th>
                    <th scope="col">Liquidation Deposit Amount</th>
                    <th scope="col">Income Tax Percentage</th>
                    <th scope="col">Spread Pay Fixed Value</th>
                    <th scope="col">Spread Receive Fixed Value</th>
                </tr>
                </thead>
                <tbody>
                {configurations.map(configuration => {
                        return (
                            <tr key={configuration.asset}>
                                <td>{configuration.asset}</td>
                                <td>{configuration.minCollateralizationFactorValue}</td>
                                <td>{configuration.maxCollateralizationFactorValue}</td>
                                <td>{configuration.openingFeePercentage}</td>
                                <td>{configuration.iporPublicationFeeAmount}</td>
                                <td>{configuration.liquidationDepositAmount}</td>
                                <td>{configuration.incomeTaxPercentage}</td>
                                <td>{configuration.spreadPayFixedValue}</td>
                                <td>{configuration.spreadRecFixedValue}</td>
                            </tr>
                        )
                    }
                )}
                </tbody>
            </table>

        </div>
    ) : <p>No configuration set</p>
);
