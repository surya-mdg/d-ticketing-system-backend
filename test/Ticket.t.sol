// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Ticket} from "../src/Ticket.sol";

contract TicketTest is Test {
    Ticket public ticket;
    address owner = vm.addr(1);
    address user1 = vm.addr(2);
    address user2 = vm.addr(3);

    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event TokenSold(address indexed buyer, uint256 indexed tokenId);

    function setUp() public {
        ticket = new Ticket();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.startPrank(user1);
        ticket.mint("","","","", block.timestamp + 120, 0, 0, 2);
        ticket.mint("","","","", block.timestamp + 120, 1, 120, 2);
        ticket.mint("","","","", block.timestamp + 120, 2, 0, 2);
        vm.stopPrank();
    }

    function test_Mint() public{
        vm.startPrank(user1);
        vm.expectEmit(true, true, false, false);
        emit TokenMinted(user1, 3);
        ticket.mint("","","","", block.timestamp + 120, 0, 0, 1);

        vm.expectRevert("Mint Error: Event time needs to be greater than current time");
        ticket.mint("","","","", 1, 0, 0, 1);
    }

    function test_Sell() public{
        vm.startPrank(user1);
        vm.expectRevert("Sell Error: Selling price cannot be greater than initial cost");
        ticket.sell(3, 0);

        //vm.expectRevert("Sell Error: Cannot transfer token after deadline");
        ticket.sell(1, 1);

        vm.expectRevert("Sell Error: Cannot transfer token after deadline");
        ticket.sell(1, 2);
    }

    function test_SellBuy() public{
        vm.prank(user1);
        ticket.sell(1, 0);

        vm.prank(user2);
        //vm.expectEmit(true, true, false, false);
        //emit TokenSold(user2, 0);
        ticket.buy{value: 3}(0);

        assertEq(ticket.verify(0, user1), false);
        assertEq(ticket.verify(0, user2), true);

        //vm.prank(user1);
        //ticket.transfer(0);

        //assertEq(ticket.verify(0, user2), true);
    }


}
