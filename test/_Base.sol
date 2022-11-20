// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MuseTime.sol";
import "../src/MuseTimeController.sol";
import "../src/libraries/ECDSA.sol";

contract BaseTestSuite is Test {
    using ECDSA for bytes32;

    struct Topic {
        uint256 valueInWei;
        bytes32 topicId;
        bytes32 topicsArId;
        bytes32 profileArId;
        address topicOwner;
    }

    MuseTime public museTime;
    MuseTimeController public museTimeController;

    string constant BASE_URI = "https://musetime.xyz/~/";
    uint256 constant PARAMS_SIGNER_PRIVATE_KEY = uint256(keccak256('verification'));

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

    function _sign(bytes memory data) internal returns (bytes memory signature) {
        bytes32 hash = keccak256(data).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PARAMS_SIGNER_PRIVATE_KEY, hash);
        signature = abi.encodePacked(r, s, v);
    }

    function _createTimeTrove(
        address msgSender,
        address topicOwner,
        bytes32 arOwnerAddress
    ) internal {
        bytes memory data = abi.encodePacked(address(museTimeController), topicOwner, arOwnerAddress);
        bytes memory signature = _sign(data);
        vm.prank(msgSender, msgSender);
        MuseTimeController.CreateTimeTroveParams[] memory params = new MuseTimeController.CreateTimeTroveParams[](1);
        params[0] = MuseTimeController.CreateTimeTroveParams({
            arOwnerAddress: arOwnerAddress,
            topicOwner: topicOwner,
            signature: signature
        });
        museTimeController.createTimeTroves(params);
    }

    function _mintTimeToken(
        address msgSender,
        uint256 expired,
        Topic memory topic
    ) internal returns (uint256 tokenId) {
        uint256 valueInWei = topic.valueInWei;
        bytes32 topicId = topic.topicId;
        bytes32 topicsArId = topic.topicsArId;
        bytes32 profileArId = topic.profileArId;
        address topicOwner = topic.topicOwner;
        // (valueInWei, profileArId, topicsArId, topicId, topicOwner) = topic;
        bytes memory data = abi.encodePacked(
            address(museTimeController), msgSender,
            expired, valueInWei, profileArId, topicsArId, topicId, topicOwner
        );
        bytes memory signature = _sign(data);
        vm.prank(msgSender, msgSender);
        tokenId = museTimeController.mintTimeToken{value:valueInWei}(
            expired, valueInWei, profileArId, topicsArId, topicId, topicOwner, signature);
    }
}
