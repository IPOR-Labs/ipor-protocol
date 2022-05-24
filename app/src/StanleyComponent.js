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
                            methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
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
                            methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
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
                            methodArgs={[drizzle.contracts.DrizzleDai.address]}
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
                        {drizzle.contracts.DrizzleShareTokenAaveUsdt.address}
                    </th>
                    <th scope="col">
                        aUSDC
                        <br />
                        {drizzle.contracts.DrizzleShareTokenAaveUsdc.address}
                    </th>
                    <th scope="col">
                        aDAI
                        <br />
                        {drizzle.contracts.DrizzleShareTokenAaveDai.address}
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
                            contract="DrizzleShareTokenAaveUsdt"
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
                            contract="DrizzleShareTokenAaveUsdc"
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
                            contract="DrizzleShareTokenAaveDai"
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
                            contract="DrizzleShareTokenAaveUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveUsdt.address]}
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
                            contract="DrizzleShareTokenAaveUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveUsdc.address]}
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
                            contract="DrizzleShareTokenAaveDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveDai.address]}
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
                        {drizzle.contracts.DrizzleShareTokenCompoundUsdt.address}
                    </th>
                    <th scope="col">
                        cUSDC
                        <br />
                        {drizzle.contracts.DrizzleShareTokenCompoundUsdc.address}
                    </th>
                    <th scope="col">
                        cDAI
                        <br />
                        {drizzle.contracts.DrizzleShareTokenCompoundDai.address}
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
                            contract="DrizzleShareTokenCompoundUsdt"
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
                            contract="DrizzleShareTokenCompoundUsdc"
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
                            contract="DrizzleShareTokenCompoundDai"
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
                            contract="DrizzleShareTokenCompoundUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundUsdt.address]}
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
                            contract="DrizzleShareTokenCompoundUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundUsdc.address]}
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
                            contract="DrizzleShareTokenCompoundDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundDai.address]}
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
                            contract="DrizzleStrategyAaveUsdt"
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
                            contract="DrizzleStrategyAaveUsdc"
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
                            contract="DrizzleStrategyAaveDai"
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
                            contract="DrizzleStrategyCompoundUsdt"
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
                            contract="DrizzleStrategyCompoundUsdc"
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
                            contract="DrizzleStrategyCompoundDai"
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
                        <strong>Strategy Aave ERC20 Token Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveUsdt.address]}
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
                            contract="DrizzleUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveUsdc.address]}
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
                            contract="DrizzleDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyAaveDai.address]}
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
                        <strong>Strategy Compound ERC20 Token Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundUsdt.address]}
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
                            contract="DrizzleUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundUsdc.address]}
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
                            contract="DrizzleDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleStrategyCompoundDai.address]}
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
                            contract="DrizzleStrategyAaveUsdt"
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
                            contract="DrizzleStrategyAaveUsdc"
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
                            contract="DrizzleStrategyAaveDai"
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
                            contract="DrizzleStrategyCompoundUsdt"
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
                            contract="DrizzleStrategyCompoundUsdc"
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
                            contract="DrizzleStrategyCompoundDai"
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

            {/* <table className="table" align="center">
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
                                contract="DrizzleUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyUsdt.address,
                                    drizzle.contracts.DrizzleStrategyAaveUsdt.address,
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
                                contract="DrizzleUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyUsdt.address,
                                    drizzle.contracts.DrizzleStrategyAaveUsdt.address,
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
                                contract="DrizzleUsdc"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyUsdc.address,
                                    drizzle.contracts.DrizzleStrategyAaveUsdc.address,
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
                                contract="DrizzleUsdc"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyUsdc.address,
                                    drizzle.contracts.DrizzleStrategyAaveUsdc.address,
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
                                contract="DrizzleDai"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfStanleyDai.address,
                                    drizzle.contracts.DrizzleStrategyAaveDai.address,
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
                                contract="DrizzleDai"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.StanleyDai.address,
                                    drizzle.contracts.DrizzleStrategyAaveDai.address,
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
            </table> */}

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
                                contract="DrizzleStrategyAaveUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveDai"
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
                                contract="DrizzleStrategyCompoundUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundDai"
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
                                contract="DrizzleStrategyAaveUsdt"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveUsdc"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveDai"
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
                                contract="DrizzleStrategyAaveUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveDai"
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
                                contract="DrizzleStrategyCompoundUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundDai"
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
                                contract="DrizzleStrategyAaveUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyAaveDai"
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
                                contract="DrizzleStrategyCompoundUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStrategyCompoundDai"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
