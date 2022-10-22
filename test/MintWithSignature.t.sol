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
        uint256 expired = 1;
        uint256 valueInWei = 0.1 ether;
        address topicOwner = EOA_SELLER;
        bytes32 topicId = 0xfed92c215725bcade15c079d387c8267cc806b58d7aec929a1071337c80887c7;
        bytes32 topicsArId = 0xfed92c215725bcade15c079d387c8267cc806b58d7aec929a1071337c80887c7;
        bytes32 profileArId = 0xfed92c215725bcade15c079d387c8267cc806b58d7aec929a1071337c80887c7;

        bytes memory data = abi.encodePacked(
            address(museTimeController), EOA_BUYER,
            expired, valueInWei, profileArId, topicsArId, topicId, topicOwner
        );
        bytes memory signature = _sign(data);

        vm.deal(EOA_BUYER, 1 ether);
        vm.prank(EOA_BUYER, EOA_BUYER);
        museTimeController.mintTimeToken{value:valueInWei}(
            expired, valueInWei, profileArId, topicsArId, topicId, topicOwner, signature);
        assertEq(museTime.tokenURI(1), "https://musetime.xyz/~/1");
        // emit log(museTime.tokenURI(1));
    }

    function _sign(bytes memory data) private returns (bytes memory signature) {
        bytes32 hash = keccak256(data).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PARAMS_SIGNER_PRIVATE_KEY, hash);
        signature = abi.encodePacked(r, s, v);
    }
}
