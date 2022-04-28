import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col"></th>
                    <th scope="col">
                        ivUSDT
                        <br />
                        {drizzle.contracts.IvTokenUsdt.address}
                    </th>
                    <th scope="col">
                        ivUSDC
                        <br />
                        {drizzle.contracts.IvTokenUsdc.address}
                    </th>
                    <th scope="col">
                        ivDAI
                        <br />
                        {drizzle.contracts.IvTokenDai.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>Exchange Rate</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyUsdt"
                                method="calculateExchangeRate"
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
                                contract="StanleyUsdt"
                                method="calculateExchangeRate"
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyUsdc"
                                method="calculateExchangeRate"
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
                                contract="StanleyUsdc"
                                method="calculateExchangeRate"
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyDai"
                                method="calculateExchangeRate"
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
                                contract="StanleyDai"
                                method="calculateExchangeRate"
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
                        <strong>My IvToken Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="CockpitDataProvider"
                            method="getMyIvTokenBalance"
                            methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
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
                            contract="CockpitDataProvider"
                            method="getMyIvTokenBalance"
                            methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
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
                            contract="CockpitDataProvider"
                            method="getMyIvTokenBalance"
                            methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
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
                        <strong>Milton IvToken Balance</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="IvTokenUsdt"
                                method="balanceOf"
                                methodArgs={[drizzle.contracts.ItfMiltonUsdt.address]}
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
                                contract="IvTokenUsdt"
                                method="balanceOf"
                                methodArgs={[drizzle.contracts.MiltonUsdt.address]}
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="IvTokenUsdc"
                                method="balanceOf"
                                methodArgs={[drizzle.contracts.ItfMiltonUsdc.address]}
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
                                contract="IvTokenUsdc"
                                method="balanceOf"
                                methodArgs={[drizzle.contracts.MiltonUsdc.address]}
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="IvTokenDai"
                                method="balanceOf"
                                methodArgs={[drizzle.contracts.ItfMiltonDai.address]}
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
                                contract="IvTokenDai"
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
            </table>

            <table className="table" align="center">
                <tr>
                    <th scope="col">Component</th>
                    <th scope="col">
                        aUSDT
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenAaveUsdt.address}
                    </th>
                    <th scope="col">
                        aUSDC
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenAaveUsdc.address}
                    </th>
                    <th scope="col">
                        aDAI
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenAaveDai.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>aToken Total Supply</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetShareTokenAaveUsdt"
                            method="totalSupply"
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
                            contract="MockTestnetShareTokenAaveUsdc"
                            method="totalSupply"
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
                            contract="MockTestnetShareTokenAaveDai"
                            method="totalSupply"
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
                        <strong>AAVE Strategy aToken Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetShareTokenAaveUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyAaveUsdt.address]}
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
                            contract="MockTestnetShareTokenAaveUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyAaveUsdc.address]}
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
                            contract="MockTestnetShareTokenAaveDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyAaveDai.address]}
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
                    <th scope="col">Component</th>
                    <th scope="col">
                        cUSDT
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenCompoundUsdt.address}
                    </th>
                    <th scope="col">
                        cUSDC
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenCompoundUsdc.address}
                    </th>
                    <th scope="col">
                        cDAI
                        <br />
                        {drizzle.contracts.MockTestnetShareTokenCompoundDai.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>cToken Total Supply</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetShareTokenCompoundUsdt"
                            method="totalSupply"
                            render={(value) => (
                                <div>
                                    {value / 100000000}
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
                            contract="MockTestnetShareTokenCompoundUsdc"
                            method="totalSupply"
                            render={(value) => (
                                <div>
                                    {value / 100000000}
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
                            contract="MockTestnetShareTokenCompoundDai"
                            method="totalSupply"
                            render={(value) => (
                                <div>
                                    {value / 100000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Compound Strategy cToken Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetShareTokenCompoundUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyCompoundUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 100000000}
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
                            contract="MockTestnetShareTokenCompoundUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyCompoundUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 100000000}
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
                            contract="MockTestnetShareTokenCompoundDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MockTestnetStrategyCompoundDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 100000000}
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
                    <th scope="col">Component</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Stanley Asset Balance</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyUsdt"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.ItfStanleyUsdt.address]}
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
                                contract="StanleyUsdt"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.StanleyUsdt.address]}
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyUsdc"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.ItfStanleyUsdc.address]}
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
                                contract="StanleyUsdc"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.StanleyUsdc.address]}
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
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfStanleyDai"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.ItfStanleyDai.address]}
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
                                contract="StanleyDai"
                                method="totalBalance"
                                methodArgs={[drizzle.contracts.StanleyDai.address]}
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
                        <strong>Strategy Aave Asset Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetStrategyAaveUsdt"
                            method="balanceOf"
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
                            contract="MockTestnetStrategyAaveUsdc"
                            method="balanceOf"
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
                            contract="MockTestnetStrategyAaveDai"
                            method="balanceOf"
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
                        <strong>Strategy Compound Asset Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetStrategyCompoundUsdt"
                            method="balanceOf"
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
                            contract="MockTestnetStrategyCompoundUsdc"
                            method="balanceOf"
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
                            contract="MockTestnetStrategyCompoundDai"
                            method="balanceOf"
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
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave Strategy APR</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetStrategyAaveUsdt"
                            method="getApr"
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
                            contract="MockTestnetStrategyAaveUsdc"
                            method="getApr"
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
                            contract="MockTestnetStrategyAaveDai"
                            method="getApr"
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
                        <strong>Compound Strategy APR</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MockTestnetStrategyCompoundUsdt"
                            method="getApr"
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
                            contract="MockTestnetStrategyCompoundUsdc"
                            method="getApr"
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
                            contract="MockTestnetStrategyCompoundDai"
                            method="getApr"
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
                    <th scope="col">Stanley Allowances</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>
                <tr>
                    <td>
                        <strong>Aave Strategy</strong>
                        <br />
                        For deposit and withdraw to Strategy
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="MockTestnetTokenUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyUsdt.address,
                                    drizzle.contracts.MockTestnetStrategyAaveUsdt.address,
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
                                contract="MockTestnetTokenUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyUsdt.address,
                                    drizzle.contracts.MockTestnetStrategyAaveUsdt.address,
                                ]}
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
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="MockTestnetTokenUsdc"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyUsdc.address,
                                    drizzle.contracts.MockTestnetStrategyAaveUsdc.address,
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
                                contract="MockTestnetTokenUsdc"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyUsdc.address,
                                    drizzle.contracts.MockTestnetStrategyAaveUsdc.address,
                                ]}
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
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="MockTestnetTokenDai"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyDai.address,
                                    drizzle.contracts.MockTestnetStrategyAaveDai.address,
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
                                contract="MockTestnetTokenDai"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyDai.address,
                                    drizzle.contracts.MockTestnetStrategyAaveDai.address,
                                ]}
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
            </table>

            <h4>Strategies claim</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="doClaim"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Compound</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="doClaim"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Strategies beforeClaim</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Strategies setTreasuryManager</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Compound</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Strategies setTreasury</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Compound</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>
            </table>

            <h4>Pause/Unpause Stanley</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Pause</strong>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdt"
                                    method="pause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdt"
                                    method="pause"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdc"
                                    method="pause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdc"
                                    method="pause"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyDai"
                                    method="pause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyDai"
                                    method="pause"
                                />
                            )}
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Unpause</strong>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdt"
                                    method="unpause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdt"
                                    method="unpause"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdc"
                                    method="unpause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdc"
                                    method="unpause"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyDai"
                                    method="unpause"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyDai"
                                    method="unpause"
                                />
                            )}
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Pause/Unpause Aave Strategy</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Pause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="pause"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Unpause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="unpause"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Pause/Unpause Compound Strategy</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Pause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="pause"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Unpause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="unpause"
                            />
                        </div>
                    </td>
                </tr>
            </table>

            <h4>Stanley</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Ownership</strong>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdt"
                                    method="transferOwnership"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdt"
                                    method="transferOwnership"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyUsdc"
                                    method="transferOwnership"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyUsdc"
                                    method="transferOwnership"
                                />
                            )}
                        </div>
                    </td>
                    <td>
                        <div>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfStanleyDai"
                                    method="transferOwnership"
                                />
                            ) : (
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="StanleyDai"
                                    method="transferOwnership"
                                />
                            )}
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Aave Strategy</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Ownership</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdt"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveUsdc"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyAaveDai"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Compound Strategy</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Action</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Ownership</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdt"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundUsdc"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="MockTestnetStrategyCompoundDai"
                                method="transferOwnership"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
