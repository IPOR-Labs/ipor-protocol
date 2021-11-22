import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div align="left">
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">ETH</th>
                <th scope="col">
                    USDT
                    <br/>
                    {drizzle.contracts.UsdtMockedToken.address}
                </th>
                <th scope="col">
                    USDC
                    <br/>
                    {drizzle.contracts.UsdcMockedToken.address}
                </th>
                <th scope="col">
                    DAI
                    <br/>
                    {drizzle.contracts.DaiMockedToken.address}
                </th>
            </tr>
            <tr>
                <td><strong>Available Faucet balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOfEth"
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td><strong>My Total Balance</strong></td>
                <td>
                    Check your wallet :)
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <div className="row">
            <div className="col-md-6">
                <strong>Transfer ETH to specific address</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFaucet"
                    method="transferEth"
                />
            </div>
            <div className="col-md-6">
                <strong>Transfer TOKENS to your wallet</strong>
                <br/>
                <label>Max allowed value 1 000 000 USD</label>
                <br/>
                <small>Max in 6 decimals: 1000000000000</small>
                <br/>
                <small>Max in 18 decimals: 1000000000000000000000000</small>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFaucet"
                    method="transfer"
                />
            </div>
        </div>
    </div>
);