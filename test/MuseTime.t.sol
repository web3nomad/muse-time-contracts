// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MuseTime.sol";
import "../src/MuseTimeController.sol";

contract MuseTimeTest is Test {
    MuseTime public museTime;
    MuseTimeController public museTimeController;
    address constant EOA1 = address(uint160(uint256(keccak256('user account 1'))));

    function setUp() public {
        museTime = new MuseTime();
        museTimeController = new MuseTimeController(address(museTime), "");
        museTime.setController(address(museTimeController));
        hoax(EOA1, 10 ether);
    }

    function testMint() public {
        vm.prank(EOA1, EOA1);
        museTimeController.mint{value: 1 ether}();
        assertEq(museTime.ownerOf(1), EOA1);
    }
}
