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
                        ipUSDT
                        <br />
                        {drizzle.contracts.IpTokenUsdt.address}
                    </th>
                    <th scope="col">
                        ipUSDC
                        <br />
                        {drizzle.contracts.IpTokenUsdc.address}
                    </th>
                    <th scope="col">
                        ipDAI
                        <br />
                        {drizzle.contracts.IpTokenDai.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>IpToken Exchange Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="calculateExchangeRate"
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
                            contract="DrizzleJosephUsdc"
                            method="calculateExchangeRate"
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
                            contract="DrizzleJosephDai"
                            method="calculateExchangeRate"
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
                        <strong>My IpToken Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="CockpitDataProvider"
                            method="getMyIpTokenBalance"
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
                            method="getMyIpTokenBalance"
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
                            method="getMyIpTokenBalance"
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
            </table>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Milton Allowances</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>
                <tr>
                    <td>
                        <strong>Stanley</strong>
                        <br />
                        For deposit and withdraw to Stanley's Strategies
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdt"
                            method="allowance"
                            methodArgs={[
                                drizzle.contracts.DrizzleMiltonUsdt.address,
                                drizzle.contracts.DrizzleStanleyUsdt.address,
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
                                drizzle.contracts.DrizzleMiltonUsdc.address,
                                drizzle.contracts.DrizzleStanleyUsdc.address,
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
                                drizzle.contracts.DrizzleMiltonDai.address,
                                drizzle.contracts.DrizzleStanleyDai.address,
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
            </table>
            <table className="table" align="center">
                <tr>
                    <th scope="col">My allowances</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>
                <tr>
                    <td>
                        <strong> Joseph</strong>
                        <br />
                        For provide liquidity
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="CockpitDataProvider"
                            method="getMyAllowanceInJoseph"
                            methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
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
                            method="getMyAllowanceInJoseph"
                            methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
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
                            method="getMyAllowanceInJoseph"
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
                    <td></td>
                    <td>
                        <strong>Joseph</strong> {drizzle.contracts.DrizzleJosephUsdt.address}
                        <ContractForm drizzle={drizzle} contract="DrizzleUsdt" method="approve" />
                    </td>
                    <td>
                        <strong>Joseph</strong> {drizzle.contracts.DrizzleJosephUsdc.address}
                        <ContractForm drizzle={drizzle} contract="DrizzleUsdc" method="approve" />
                    </td>
                    <td>
                        <strong>Joseph</strong> {drizzle.contracts.DrizzleJosephDai.address}
                        <ContractForm drizzle={drizzle} contract="DrizzleDai" method="approve" />
                    </td>
                </tr>
            </table>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.DrizzleUsdt.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.DrizzleUsdc.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DrizzleDai.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Provide Liquidity</strong>
                        <br />
                        <small>
                            Transfer from Liquidity Provider to Milton Liquidity Pool using Joseph.
                            <br />
                            Asset amount represented in 18 decimals.
                        </small>
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdt"
                            method="provideLiquidity"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdc"
                            method="provideLiquidity"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephDai"
                            method="provideLiquidity"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem</strong>
                        <br />
                        <small>
                            Transfer from Milton Liquidity Pool to Liquidity Provider using Joseph.
                            <br />
                            Ip Token amount represented in 18 decimals.
                        </small>
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdt"
                            method="redeem"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdc"
                            method="redeem"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephDai"
                            method="redeem"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Rebalance</strong>
                        <br />
                        <small>
                            Rebalance cash between Milton balance and Strategies (AAVE and Compound)
                            balance
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="rebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="rebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="rebalance"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Deposit to Stanley</strong>
                        <br />
                        <small>
                            Transfer from Milton via Stanley to Strategy (AAVE or Compound).
                            <br />
                            Asset amount represented in 18 decimals.
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="depositToStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="depositToStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="depositToStanley"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Withdraw from Stanley</strong>
                        <br />
                        <small>
                            Transfer from Strategy (AAVE or Compound) via Stanley to Milton.
                            <br />
                            Asset amount represented in 18 decimals.
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="withdrawFromStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="withdrawFromStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="withdrawFromStanley"
                            />
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Withdraw ALL from Stanley</strong>
                        <br />
                        <small>
                            Transfer ALL cash from Strategy (AAVE or Compound) via Stanley to Milton
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="withdrawAllFromStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="withdrawAllFromStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="withdrawAllFromStanley"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Treasury</strong>
                        <br />
                        <small>
                            Income fee, part of opening fee. <br />
                            Asset amount represented in 18 decimals.
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="transferToTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="transferToTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="transferToTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>
                            Transfer to Charlie Treasury
                            <br />
                            Asset amount represented in 18 decimals.
                        </strong>
                        <small>Publication Fee</small>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="transferToCharlieTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="transferToCharlieTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="transferToCharlieTreasury"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
