import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col">SPREAD</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>SPREAD Pay Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(item) => (
                            <div>
                                {item.spreadPayFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(item) => (
                            <div>
                                {item.spreadPayFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(item) => (
                            <div>
                                {item.spreadPayFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>SPREAD Receive Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(item) => (
                            <div>
                                {item.spreadReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(item) => (
                            <div>
                                {item.spreadReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="calculateSpread"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(item) => (
                            <div>
                                {item.spreadReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{item.spreadReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>

        <hr />
    </div>
);
