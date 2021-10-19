import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import logo from "./logo.png";
import {Container, Navbar, Tabs} from "react-bootstrap";
import {Tab} from "bootstrap";
import IporIndexComponent from "./WarrenComponent";
import MiltonComponent from "./MiltonComponent";
import MyPositions from "./MyPositions";
import IporConfiguration from "./IporConfigurationComponent";
import FaucetComponent from "./FaucetComponent";

require('dotenv').config({path: '../../.env'});
const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => {
    return (
        <div className="App">
            <Container>
                <Navbar fixed="top" bg="dark" variant="dark">
                    <Navbar.Brand href="#home">
                        <img
                            alt=""
                            src={logo}
                            width="30"
                            height="30"
                            className="d-inline-block align-top ipor-navbar"
                        />{' '}
                        IPOR Protocol - MILTON Dev Tool
                    </Navbar.Brand>
                </Navbar>
            </Container>

            <div className="section">
                <p>Active Account</p>
                <AccountData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    accountIndex={0}
                    units="ether"
                    precision={3}

                />
            </div>

            <Tabs defaultActiveKey="profile" id="uncontrolled-tab-example">
                <Tab eventKey="iporIndex" title="Warren Oracle">
                    <IporIndexComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="miltonOverview" title="Milton Overview">
                    <MiltonComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="miltonConfig" title="IPOR Config">
                    <IporConfiguration
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="myPositions" title="My positions">
                    <MyPositions
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="faucet" title="Faucet">
                    <FaucetComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
            </Tabs>
        </div>
    );
}
