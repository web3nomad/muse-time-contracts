// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/MuseTime.sol";
import "../src/MuseTimeController.sol";
import "./_Base.sol";

contract MuseTimeTest is BaseTestSuite {
    address constant TOPIC_OWNER = address(uint160(uint256(keccak256('user account 0'))));
    address constant EOA_BUYER_1 = address(uint160(uint256(keccak256('user account 1'))));
    address constant EOA_BUYER_2 = address(uint160(uint256(keccak256('user account 2'))));

    bytes32 arOwnerAddress = bytes32(uint256(0x1));
    Topic topic = Topic({
        valueInWei: 0.1 ether,
        topicId: bytes32(uint256(0x10)),
        topicsArId: bytes32(uint256(0x11)),
        profileArId: bytes32(uint256(0x12)),
        topicOwner: TOPIC_OWNER
    });

    function testBalance() public {
        uint256 expired = 1;
        vm.deal(TOPIC_OWNER, 1 ether);
        vm.deal(EOA_BUYER_1, 1 ether);
        _createTimeTrove(TOPIC_OWNER, topic.topicOwner, arOwnerAddress);

        _mintTimeToken(EOA_BUYER_1, expired, topic);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
    }

    function testBalanceAfterConfirm() public {
        uint256 expired = 3;
        vm.deal(TOPIC_OWNER, 0 ether);
        vm.deal(EOA_BUYER_1, 1 ether);
        vm.deal(EOA_BUYER_2, 1 ether);
        // any one can create time trove for others
        _createTimeTrove(msg.sender, topic.topicOwner, arOwnerAddress);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = _mintTimeToken(EOA_BUYER_1, expired, topic);
        tokenIds[1] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, 0);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setConfirmed(tokenIds, false);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, topic.valueInWei * 2);
        assertEq(TOPIC_OWNER.balance, 0);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.withdrawFromTimeTrove();
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, topic.valueInWei * 2);
    }

    function testConfirmAndWithdraw() public {
        uint256 expired = 3;
        vm.deal(TOPIC_OWNER, 0.01 ether);
        vm.deal(EOA_BUYER_1, 1 ether);
        vm.deal(EOA_BUYER_2, 1 ether);
        // any one can create time trove for others
        _createTimeTrove(msg.sender, topic.topicOwner, arOwnerAddress);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = _mintTimeToken(EOA_BUYER_1, expired, topic);
        tokenIds[1] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        tokenIds[2] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, 0.01 ether);

        // emit log_uint(TOPIC_OWNER.balance);
        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setConfirmed(tokenIds, true);
        // emit log_uint(TOPIC_OWNER.balance);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, 0.01 ether + topic.valueInWei * 3);
    }

    function testReject() public {
        uint256 expired = 3;
        vm.deal(TOPIC_OWNER, 0);
        vm.deal(EOA_BUYER_1, 1 ether);
        vm.deal(EOA_BUYER_2, 1 ether);
        _createTimeTrove(msg.sender, topic.topicOwner, arOwnerAddress);

        uint256[] memory tokenIdsConfirm = new uint256[](2);
        uint256[] memory tokenIdsReject = new uint256[](1);
        tokenIdsConfirm[0] = _mintTimeToken(EOA_BUYER_1, expired, topic);
        tokenIdsConfirm[1] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        tokenIdsReject[0] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        // contract balance is 0.03
        assertEq(address(museTimeController).balance, topic.valueInWei * 3);
        assertEq(EOA_BUYER_1.balance, 1 ether - topic.valueInWei);
        assertEq(EOA_BUYER_2.balance, 1 ether - topic.valueInWei * 2);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setConfirmed(tokenIdsConfirm, true);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, topic.valueInWei * 2);
        assertEq(address(museTimeController).balance, topic.valueInWei);
        assertEq(EOA_BUYER_1.balance, 1 ether - topic.valueInWei);
        assertEq(EOA_BUYER_2.balance, 1 ether - topic.valueInWei * 2);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setRejected(tokenIdsReject);
        assertEq(TOPIC_OWNER.balance, topic.valueInWei * 2);
        assertEq(address(museTimeController).balance, 0);
        assertEq(EOA_BUYER_1.balance, 1 ether - topic.valueInWei);
        assertEq(EOA_BUYER_2.balance, 1 ether - topic.valueInWei);
    }

    function testWithdrawFee() public {
        museTimeController.setFeeDivisor(100);

        uint256 expired = 3;
        vm.deal(TOPIC_OWNER, 0);
        vm.deal(EOA_BUYER_1, 1 ether);
        vm.deal(EOA_BUYER_2, 1 ether);
        _createTimeTrove(msg.sender, topic.topicOwner, arOwnerAddress);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = _mintTimeToken(EOA_BUYER_1, expired, topic);
        tokenIds[1] = _mintTimeToken(EOA_BUYER_2, expired, topic);
        tokenIds[2] = _mintTimeToken(EOA_BUYER_2, expired, topic);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setConfirmed(tokenIds, true);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        // fee is 1%, owner will get 99%
        assertEq(TOPIC_OWNER.balance, topic.valueInWei * 3 * 99 / 100);
    }

    function testWithdrawNoFee() public {
        museTimeController.setFeeDivisor(0);

        uint256 expired = 1;
        vm.deal(EOA_BUYER_1, 1 ether);
        vm.deal(EOA_BUYER_2, 1 ether);
        _createTimeTrove(msg.sender, topic.topicOwner, arOwnerAddress);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = _mintTimeToken(EOA_BUYER_1, expired, topic);
        tokenIds[1] = _mintTimeToken(EOA_BUYER_2, expired, topic);

        vm.prank(TOPIC_OWNER, TOPIC_OWNER);
        museTimeController.setConfirmed(tokenIds, true);
        assertEq(museTimeController.timeTroveOf(TOPIC_OWNER).balance, 0);
        assertEq(TOPIC_OWNER.balance, topic.valueInWei * 2);
    }

}
