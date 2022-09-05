import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col"></th>
                    <th scope="col">
                        ivUSDT
                        <br/>
                        {drizzle.contracts.IvTokenUsdt.address}
                    </th>
                    <th scope="col">
                        ivUSDC
                        <br/>
                        {drizzle.contracts.IvTokenUsdc.address}
                    </th>
                    <th scope="col">
                        ivDAI
                        <br/>
                        {drizzle.contracts.IvTokenDai.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>Exchange Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyUsdt"
                            method="calculateExchangeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyUsdc"
                            method="calculateExchangeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyDai"
                            method="calculateExchangeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IvTokenUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleMiltonUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IvTokenUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleMiltonUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IvTokenDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.DrizzleMiltonDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
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
                        aUSDT
                        <br/>
                        {drizzle.contracts.DrizzleShareTokenAaveUsdt.address}
                    </th>
                    <th scope="col">
                        aUSDC
                        <br/>
                        {drizzle.contracts.DrizzleShareTokenAaveUsdc.address}
                    </th>
                    <th scope="col">
                        aDAI
                        <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                        <br/>
                        {drizzle.contracts.DrizzleShareTokenCompoundUsdt.address}
                    </th>
                    <th scope="col">
                        cUSDC
                        <br/>
                        {drizzle.contracts.DrizzleShareTokenCompoundUsdc.address}
                    </th>
                    <th scope="col">
                        cDAI
                        <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyUsdt"
                            method="totalBalance"
                            methodArgs={[drizzle.contracts.DrizzleStanleyUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyUsdc"
                            method="totalBalance"
                            methodArgs={[drizzle.contracts.DrizzleStanleyUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleStanleyDai"
                            method="totalBalance"
                            methodArgs={[drizzle.contracts.DrizzleStanleyDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Strategy Aave ERC20 Token Balance</strong>
                        <br/>
                        <small>Most time should be equal 0</small>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Strategy Compound ERC20 Token Balance</strong>
                        <br/>
                        <small>Most time should be equal 0.</small>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                    
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.DrizzleStanleyUsdt.address,
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
                       
                    </td>
                    <td>
                  
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleUsdc"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.DrizzleStanleyUsdc.address,
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
                       
                    </td>
                    <td>
                         
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleDai"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.DrizzleStanleyDai.address,
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

            <h4>Stanley - migrate assets to strategy with MAX APR</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdt"
                                method="migrateAssetToStrategyWithMaxApr"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdc"
                                method="migrateAssetToStrategyWithMaxApr"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyDai"
                                method="migrateAssetToStrategyWithMaxApr"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
