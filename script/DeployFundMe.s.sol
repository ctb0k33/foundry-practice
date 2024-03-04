// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {FundMe} from "../src/FundMe.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() public returns (FundMe) {
        // before broadcast -> not a "real" tex
        HelperConfig config = new HelperConfig();
        address _priceFeed = config.activeNetworkConfig();
        // after broadcast -> real tex
        vm.startBroadcast();
        FundMe fundMe = new FundMe(_priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
