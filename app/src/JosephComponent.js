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
                        <strong>Exchange Rate</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
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
                                contract="JosephUsdt"
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
                                contract="ItfJosephUsdc"
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
                                contract="JosephUsdc"
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
                                contract="ItfJosephDai"
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
                                contract="JosephDai"
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
                        <strong>My IpToken Balance</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="CockpitDataProvider"
                            method="getMyIpTokenBalance"
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
                            method="getMyIpTokenBalance"
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
                            method="getMyIpTokenBalance"
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
                        <strong>
                            {process.env.REACT_APP_ITF_ENABLED === "true"
                                ? "ITF Stanley"
                                : "Stanley"}
                        </strong>
                        <br />
                        For deposit and withdraw to Stanley's Strategies
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="MockTestnetTokenUsdt"
                                method="allowance"
                                methodArgs={[
                                    drizzle.contracts.ItfMiltonUsdt.address,
                                    drizzle.contracts.ItfStanleyUsdt.address,
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
                                    drizzle.contracts.MiltonUsdt.address,
                                    drizzle.contracts.StanleyUsdt.address,
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
                                    drizzle.contracts.ItfMiltonUsdc.address,
                                    drizzle.contracts.ItfStanleyUsdc.address,
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
                                    drizzle.contracts.MiltonUsdc.address,
                                    drizzle.contracts.StanleyUsdc.address,
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
                                    drizzle.contracts.ItfMiltonDai.address,
                                    drizzle.contracts.ItfStanleyDai.address,
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
                                    drizzle.contracts.MiltonDai.address,
                                    drizzle.contracts.StanleyDai.address,
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
            <table className="table" align="center">
                <tr>
                    <th scope="col">My allowances</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>
                <tr>
                    <td>
                        <strong>
                            {process.env.REACT_APP_ITF_ENABLED === "true" ? "ITF Joseph" : "Joseph"}
                        </strong>
                        <br />
                        For provide liquidity
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="CockpitDataProvider"
                            method="getMyAllowanceInJoseph"
                            methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
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
                            methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
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
                    <td></td>
                    <td>
                        <strong>Joseph</strong>{" "}
                        {process.env.REACT_APP_ITF_ENABLED === "true"
                            ? drizzle.contracts.ItfJosephUsdt.address
                            : drizzle.contracts.JosephUsdt.address}
                        <ContractForm
                            drizzle={drizzle}
                            contract="MockTestnetTokenUsdt"
                            method="approve"
                        />
                    </td>
                    <td>
                        <strong>Joseph</strong>{" "}
                        {process.env.REACT_APP_ITF_ENABLED === "true"
                            ? drizzle.contracts.ItfJosephUsdc.address
                            : drizzle.contracts.JosephUsdc.address}
                        <ContractForm
                            drizzle={drizzle}
                            contract="MockTestnetTokenUsdc"
                            method="approve"
                        />
                    </td>
                    <td>
                        <strong>Joseph</strong>{" "}
                        {process.env.REACT_APP_ITF_ENABLED === "true"
                            ? drizzle.contracts.ItfJosephDai.address
                            : drizzle.contracts.JosephDai.address}
                        <ContractForm
                            drizzle={drizzle}
                            contract="MockTestnetTokenDai"
                            method="approve"
                        />
                    </td>
                </tr>
            </table>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.MockTestnetTokenUsdt.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.MockTestnetTokenUsdc.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.MockTestnetTokenDai.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Provide Liquidity</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdt"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdt"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdc"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdc"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephDai"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephDai"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdt"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm drizzle={drizzle} contract="JosephUsdt" method="redeem" />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdc"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm drizzle={drizzle} contract="JosephUsdc" method="redeem" />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephDai"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm drizzle={drizzle} contract="JosephDai" method="redeem" />
                        )}
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
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Deposit to Stanley</strong>
                        <br />
                        <small>
                            Transfer from Milton via Stanley to Strategy (AAVE or Compound)
                        </small>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="depositToStanley"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="depositToStanley"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="depositToStanley"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Withdraw from Stanley</strong>
                        <br />
                        <small>
                            Transfer from Strategy (AAVE or Compound) via Stanley to Milton
                        </small>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="withdrawFromStanley"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Treasury</strong>
                        <br />
                        <small>Income fee, part of opening fee</small>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="transferToTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="transferToTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="transferToTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="transferToTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="transferToTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="transferToTreasury"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer to Charlie Treasury</strong>
                        <small>Publication Fee</small>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="transferToCharlieTreasury"
                                />
                            </div>
                        )}
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
