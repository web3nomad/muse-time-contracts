// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "forge-std/Test.sol";
import "../src/MuseTime.sol";
import "../src/MuseTimeController.sol";
import "./_Base.sol";

contract MuseTimeTest is BaseTestSuite {

    address constant EOA_SELLER = address(uint160(uint256(keccak256('user account 1'))));
    address constant EOA_BUYER = address(uint160(uint256(keccak256('user account 2'))));

    function testMintWithSignatureSuccess() public {
        uint256 expired = 1;
        uint256 valueInWei = 0.1 ether;
        bytes32 topicId = 0x0000000000000000000000000000000000000000000000000000000000000010;
        bytes32 topicsArId = 0x0000000000000000000000000000000000000000000000000000000000000011;
        bytes32 profileArId = 0x0000000000000000000000000000000000000000000000000000000000000012;
        address topicOwner = EOA_SELLER;

        bytes32 arOwnerAddress = 0x0000000000000000000000000000000000000000000000000000000000000001;
        vm.deal(EOA_SELLER, 1 ether);
        _createTimeTrove(EOA_SELLER, topicOwner, arOwnerAddress);

        Topic memory topic = Topic(valueInWei, topicId, topicsArId, profileArId, topicOwner);
        vm.deal(EOA_BUYER, 1 ether);
        _mintTimeToken(EOA_BUYER, expired, topic);

        assertEq(museTime.tokenURI(1), "https://musetime.xyz/~/1");
        // emit log(museTime.tokenURI(1));
    }

}
