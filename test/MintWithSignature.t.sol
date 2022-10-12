// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MuseTime.sol";
import "../src/MuseTimeController.sol";
import "../src/libraries/ECDSA.sol";

contract MuseTimeTest is Test {
    using ECDSA for bytes32;

    MuseTime public museTime;
    MuseTimeController public museTimeController;

    string constant BASE_URI = "https://musetime.xyz/~/";
    uint256 constant PARAMS_SIGNER_PRIVATE_KEY = uint256(keccak256('verification'));
    address constant EOA_SELLER = address(uint160(uint256(keccak256('user account 1'))));
    address constant EOA_BUYER = address(uint160(uint256(keccak256('user account 2'))));

    function setUp() public {
        address paramsSigner = vm.addr(PARAMS_SIGNER_PRIVATE_KEY);
        museTime = new MuseTime();
        museTimeController = new MuseTimeController();
        museTimeController.initialize(
            address(museTime),
            BASE_URI,
            paramsSigner
        );
        museTime.setController(address(museTimeController));
    }

    function testMintWithSignatureSuccess() public {
        uint256 mintKey = 1;
        uint256 valueInWei = 0.1 ether;
        address topicOwner = EOA_SELLER;
        string memory topicSlug = "NzViMWU2ZWItNTA0Yi00ZmFkLWFmNzQtOWQ5MmQ5";
        string memory topicsArId = "_tksIVclvK3hXAedOHyCZ8yAa1jXrskpoQcTN8gIh8c";
        string memory profileArId = "Ubh2C3ygHLqMLoLLoq6gAImZUuEZvfoEq3EecFw56J8";

        bytes memory data = abi.encodePacked(
            EOA_BUYER, mintKey, valueInWei, topicOwner, topicSlug, profileArId, topicsArId, address(museTimeController));
        bytes memory signature = _sign(data);

        vm.deal(EOA_BUYER, 1 ether);
        vm.prank(EOA_BUYER, EOA_BUYER);
        museTimeController.mintTimeToken{value:valueInWei}(
            mintKey, valueInWei, topicOwner, topicSlug, profileArId, topicsArId, signature);
        assertEq(museTime.tokenURI(1), "https://musetime.xyz/~/1/NzViMWU2ZWItNTA0Yi00ZmFkLWFmNzQtOWQ5MmQ5/_tksIVclvK3hXAedOHyCZ8yAa1jXrskpoQcTN8gIh8c");
        // emit log(museTime.tokenURI(1));
    }

    function _sign(bytes memory data) private returns (bytes memory signature) {
        bytes32 hash = keccak256(data).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PARAMS_SIGNER_PRIVATE_KEY, hash);
        signature = abi.encodePacked(r, s, v);
    }
}
