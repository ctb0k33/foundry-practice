// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // this will return the address of a fake user
    uint256 private constant FUND_NUMBER = 0.1 ether;
    uint256 private constant START_VALUE = 10 ether;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: FUND_NUMBER}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_VALUE); // make the fake user have some FUND in account
    }

    function testMiniumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        console.log(fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expect next line to throw revert
        fundMe.fund();
    }

    function testFundUpdateFundedDataStructure() public {
        vm.prank(USER);
        // make the next call is from the user
        fundMe.fund{value: FUND_NUMBER}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, FUND_NUMBER);
    }

    function testAddsFunderToFunderArray() public {
        vm.prank(USER);
        fundMe.fund{value: FUND_NUMBER}();
        // we choice index 0 because test-suite always re-setup after one test
        address funderAddress = fundMe.getFunders(0);
        assertEq(USER, funderAddress);
    }

    function testOnlyOwnerCanWithDraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithSingleFunder() public funded {
        // Arrange
        uint256 contractFundBeforeWithdraw = address(fundMe).balance;
        uint256 ownerBalanceBeforeWithdraw = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 contactFundAfterWithdraw = address(fundMe).balance;
        uint256 ownerBalanceAfterWithdraw = fundMe.getOwner().balance;
        assertEq(contactFundAfterWithdraw, 0);
        assertEq(ownerBalanceBeforeWithdraw + contractFundBeforeWithdraw, ownerBalanceAfterWithdraw);
    }

    function testWithDrawWithMultipleFunders() public funded {
        // Arrange
        // uint160 because we can generate fake address with uint160
        uint160 fundersNumber = 10;
        for (uint160 i = 1; i <= fundersNumber; i++) {
            // hoax = make a fake address (prank) + add some fake fund (deal)
            hoax(address(i), FUND_NUMBER);
            fundMe.fund{value: FUND_NUMBER}();
        }
        uint256 contractFundBeforeWithdraw = address(fundMe).balance;
        uint256 ownerFundBeforeWithdraw = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 contactFundAfterWithdraw = address(fundMe).balance;
        uint256 ownerFundAfterWithdraw = fundMe.getOwner().balance;
        assertEq(contactFundAfterWithdraw, 0);
        assertEq(ownerFundBeforeWithdraw + contractFundBeforeWithdraw, ownerFundAfterWithdraw);
    }
}
