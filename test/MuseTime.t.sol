// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MuseTime.sol";
import "../src/MuseTimeSimpleController.sol";

contract MuseTimeTest is Test {
    MuseTime public museTime;
    MuseTimeSimpleController public museTimeController;
    address constant EOA1 = address(uint160(uint256(keccak256('user account 1'))));

    function setUp() public {
        museTime = new MuseTime();
        museTimeController = new MuseTimeSimpleController(address(museTime), "test://");
        museTime.setController(address(museTimeController));
        vm.deal(EOA1, 10 ether);
    }

    function testMint() public {
        vm.prank(EOA1, EOA1);
        museTimeController.mint{value: 1 ether}();
        assertEq(museTime.ownerOf(1), EOA1);
    }

    function testTokenURI() public {
        vm.prank(EOA1, EOA1);
        museTimeController.mint{value: 1 ether}();
        assertEq(museTime.tokenURI(1), "test://1");
        // emit log(museTime.tokenURI(1));
        // vm.writeFile("./test/test.txt", museTime.tokenURI(1));
    }
}