import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">ETH</th>
                <th scope="col">
                    USDT
                    <br />
                    {drizzle.contracts.UsdtTestnetMockedToken.address}
                </th>
                <th scope="col">
                    USDC
                    <br />
                    {drizzle.contracts.UsdcTestnetMockedToken.address}
                </th>
                <th scope="col">
                    DAI
                    <br />
                    {drizzle.contracts.DaiTestnetMockedToken.address}
                </th>
            </tr>
            <tr>
                <td>
                    <strong>Available Faucet balance</strong>
                    <br />
                    <small>Represented in decimals specific for asset</small>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOfEth"
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.UsdtTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.UsdcTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DaiTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>My Total Balance</strong>
                    <br />
                    <small>Represented in decimals specific for asset</small>
                </td>
                <td>Check your wallet :)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.UsdtTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.UsdcTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DaiTestnetMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <div className="row">
            <div className="col-md-4">
                <strong>Transfer ETH to specific address</strong>
                <br />
                <small>Value represented in WEI</small>
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="transferEth" />
            </div>
            <div className="col-md-4">
                <strong>Transfer TOKENS to your wallet</strong>
                <br />
                <label>Max allowed value $1 000 000 USD</label>
                <br />
                <small>Max in 6 decimals: 1000000000000</small>
                <br />
                <small>Max in 18 decimals: 1000000000000000000000000</small>
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="transfer" />
            </div>
            <div className="col-md-4">
                <small>Claim stable</small>
                <br />
                <label>First time  $50 000 USD</label>
                <br />
                <small>Next  $10 000 USD</small>
                <br />
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="claim" />
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="claim" />
            </div>
        </div>

    </div>
);
