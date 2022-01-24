import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import IporAssetConfigurationDai from "./contracts/IporAssetConfigurationDai.json";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>
                    <strong>Milton Total Balance</strong>
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="UsdtMockedToken"
                            method="balanceOf"
                            methodArgs={[
                                drizzle.contracts.ItfMiltonUsdt.address,
                            ]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="UsdtMockedToken"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="UsdcMockedToken"
                            method="balanceOf"
                            methodArgs={[
                                drizzle.contracts.ItfMiltonUsdc.address,
                            ]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="UsdcMockedToken"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DaiMockedToken"
                            method="balanceOf"
                            methodArgs={[
                                drizzle.contracts.ItfMiltonDai.address,
                            ]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DaiMockedToken"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>My Total Balance</strong>
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">
                    ipUSDT
                    <br />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAssetConfigurationUsdt"
                        method="getIpToken"
                    />
                </th>
                <th scope="col">
                    ipUSDC
                    <br />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAssetConfigurationUsdc"
                        method="getIpToken"
                    />
                </th>
                <th scope="col">
                    ipDAI
                    <br />
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAssetConfigurationDai"
                        method="getIpToken"
                    />
                </th>
            </tr>
            <tr>
                <td>
                    <strong>My ipToken Balance</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyIpTokenBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyIpTokenBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyIpTokenBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
        <hr />
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
                    <br />
                    <small>For opening and closing swap</small>
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
                    <strong>Joseph</strong>
                    <br />
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInJoseph"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowanceInJoseph"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
                <td></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAssetConfigurationUsdt"
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
                        contract="IporAssetConfigurationUsdt"
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
                        contract="IporAssetConfigurationUsdc"
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
                        contract="IporAssetConfigurationUsdc"
                        method="getJoseph"
                        render={(value) => (
                            <div>
                                Joseph: <strong>{value}</strong>
                            </div>
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
                        contract="IporAssetConfigurationDai"
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
                        contract="IporAssetConfigurationDai"
                        method="getJoseph"
                        render={(value) => (
                            <div>
                                Joseph: <strong>{value}</strong>
                            </div>
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

        <hr />
    </div>
);
