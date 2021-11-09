import React from "react";
import {newContextComponents} from "@drizzle/react-components";


const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div align="left">
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>ERC20 Token Address</strong></td>
                <td>
                    {drizzle.contracts.UsdtMockedToken.address}
                </td>
                <td>
                    {drizzle.contracts.UsdcMockedToken.address}
                </td>
                <td>
                    {drizzle.contracts.DaiMockedToken.address}
                </td>
            </tr>
            <tr>
                <td><strong>Milton Total Balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMiltonTotalSupply"
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
                        method="getMiltonTotalSupply"
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
                        method="getMiltonTotalSupply"
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
        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col">My allowances</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>
                    <strong>Milton</strong>
                    <br/>
                    <small>For opening and closing position</small>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInMilton"
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
                        method="getMyAllowanceInMilton"
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
                        method="getMyAllowanceInMilton"
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
                <td>
                    <strong>Joseph</strong>
                    <br/>
                    <small>For provide liquidity</small>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInJoseph"
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
                        method="getMyAllowanceInJoseph"
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
                        method="getMyAllowanceInJoseph"
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
                <td></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getMilton"
                        render={(value) => (
                            <div>
                                Milton: <strong>{value}</strong>
                            </div>
                        )}
                    />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getJoseph"
                        render={(value) => (
                            <div>
                                Joseph: <strong>{value}</strong>
                            </div>
                        )}
                    />
                    <ContractForm
                        drizzle={drizzle}
                        contract="UsdtMockedToken"
                        method="approve"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getMilton"
                        render={(value) => (
                            <div>Milton: <strong>{value}</strong></div>
                        )}
                    />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getJoseph"
                        render={(value) => (
                            <div>Joseph: <strong>{value}</strong></div>
                        )}
                    />
                    <ContractForm
                        drizzle={drizzle}
                        contract="UsdcMockedToken"
                        method="approve"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getMilton"
                        render={(value) => (
                            <div>Milton: <strong>{value}</strong></div>
                        )}
                    />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getJoseph"
                        render={(value) => (
                            <div>Joseph: <strong>{value}</strong></div>
                        )}
                    />
                    <ContractForm
                        drizzle={drizzle}
                        contract="DaiMockedToken"
                        method="approve"
                    />
                </td>
            </tr>
        </table>
        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>My Total Balance</strong></td>
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
        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">
                    ipUSDT
                    <br/>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getIpToken"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                    />
                </th>
                <th scope="col">
                    ipUSDC
                    <br/>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getIpToken"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                    />
                </th>
                <th scope="col">
                    ipDAI
                    <br/>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAddressesManager"
                        method="getIpToken"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                    />
                </th>
            </tr>
            <tr>
                <td><strong>My ipToken Balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyIpTokenBalance"
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
                        method="getMyIpTokenBalance"
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
                        method="getMyIpTokenBalance"
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
        <hr/>
    </div>
);