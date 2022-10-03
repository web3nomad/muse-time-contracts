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

    string constant BASE_URI = "https://arseed.web3infra.dev/";
    uint256 constant VERIFICATION_PRIVATE_KEY = uint256(keccak256('verification'));
    address constant EOA_SELLER = address(uint160(uint256(keccak256('user account 1'))));
    address constant EOA_BUYER = address(uint160(uint256(keccak256('user account 2'))));

    function setUp() public {
        address verificationAddress = vm.addr(VERIFICATION_PRIVATE_KEY);
        museTime = new MuseTime();
        museTimeController = new MuseTimeController(
            address(museTime),
            BASE_URI,
            verificationAddress
        );
        museTime.setController(address(museTimeController));
    }

    function testMintWithSignatureSuccess() public {
        uint256 valueInWei = 0.1 ether;
        address topicOwner = EOA_SELLER;
        string memory slug = "m5judnbyNBVKvv3QGfizA9295fLw1lq2MNU3B01NBSw";

        bytes memory data = abi.encodePacked(
            EOA_BUYER, valueInWei, topicOwner, slug, address(museTimeController));
        bytes memory signature = _sign(data);

        vm.deal(EOA_BUYER, 1 ether);
        vm.prank(EOA_BUYER, EOA_BUYER);
        museTimeController.mintWithSignature{value:valueInWei}(
            valueInWei, topicOwner, slug, signature);
        assertEq(museTime.tokenURI(1), "https://arseed.web3infra.dev/m5judnbyNBVKvv3QGfizA9295fLw1lq2MNU3B01NBSw");
        // emit log(museTime.tokenURI(1));
    }

    function _sign(bytes memory data) private returns (bytes memory signature) {
        bytes32 hash = keccak256(data).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(VERIFICATION_PRIVATE_KEY, hash);
        signature = abi.encodePacked(r, s, v);
    }
}
