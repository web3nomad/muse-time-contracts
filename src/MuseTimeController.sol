// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "solmate/utils/LibString.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SignatureVerification.sol";

contract MuseTimeController is OwnableUpgradeable {

    struct TimeTrove {
        string arOwnerAddress;
        uint256 balance;
    }

    enum TimeTokenStatus {
        PENDING,
        REJECTED,
        CONFIRMED,
        FULFILLED
    }

    struct TimeToken {
        uint256 valueInWei;
        address topicOwner;
        string topicSlug;
        string arId;
        TimeTokenStatus status;
    }

    address public museTimeNFT;
    address public verificationAddress;

    string public baseURI;
    uint256 public mintIndex;

    mapping(address => TimeTrove) internal _timeTroves;

    mapping(uint256 => TimeToken) internal _timeTokens;

    /* variables end */

    event TimeTroveCreated(address indexed topicOwner);
    event TimeTokenMinted(
        address indexed topicOwner, string indexed topicSlug, address indexed tokenOwner,
        uint256 tokenId);

    /* events end */

    function initialize(
        address museTimeNFT_,
        string memory baseURI_,
        address verificationAddress_
    ) initializer public {
        __Ownable_init();
        museTimeNFT = museTimeNFT_;
        baseURI = baseURI_;
        verificationAddress = verificationAddress_;
    }

    /**
     *  @dev TimeTrove
     */

    function createTimeTrove(string memory arOwnerAddress, bytes memory signature) external {
        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, arOwnerAddress, this),
            signature,
            verificationAddress
        );
        TimeTrove memory timeTrove = TimeTrove(arOwnerAddress, 0);
        _timeTroves[msg.sender] = timeTrove;
        emit TimeTroveCreated(msg.sender);
    }

    function timeTroveOf(address topicOwner) external view returns (TimeTrove memory) {
        return _timeTroves[topicOwner];
    }

    /**
     *  @dev TimeToken
     */

    function mintTimeToken(
        uint256 valueInWei,
        address topicOwner,
        string memory topicSlug,
        string memory arId,
        bytes memory signature
    ) external payable {
        require(valueInWei == msg.value, "Incorrect ether value");
        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, valueInWei, topicOwner, topicSlug, arId, this),
            signature,
            verificationAddress
        );
        mintIndex += 1;
        TimeToken memory timeToken = TimeToken(
            valueInWei, topicOwner, topicSlug, arId, TimeTokenStatus.PENDING);
        _timeTokens[mintIndex] = timeToken;
        IMuseTime(museTimeNFT).mint(msg.sender, mintIndex);
        emit TimeTokenMinted(topicOwner, topicSlug, msg.sender, mintIndex);
    }

    function timeTokenOf(uint256 tokenId) external view returns (TimeToken memory) {
        return _timeTokens[tokenId];
    }

    function setConfirmed(uint256 tokenId) external {
        IMuseTime(museTimeNFT).ownerOf(tokenId);  // get owner first to ensure token exists
        TimeToken memory timeToken = _timeTokens[tokenId];
        // require(timeToken.topicOwner != address(0));  // since token exists, this is not necessary
        require(msg.sender == timeToken.topicOwner, "NOT_TOPIC_OWNER");
        require(timeToken.status == TimeTokenStatus.PENDING, "WRONG_STATUS");
        _timeTokens[tokenId].status = TimeTokenStatus.CONFIRMED;
    }

    function setRejected(uint256 tokenId) external {
        address tokenOwner = IMuseTime(museTimeNFT).ownerOf(tokenId);
        TimeToken memory timeToken = _timeTokens[tokenId];
        require(msg.sender == timeToken.topicOwner, "NOT_TOPIC_OWNER");
        require(timeToken.status == TimeTokenStatus.PENDING, "WRONG_STATUS");
        _timeTokens[tokenId].status = TimeTokenStatus.REJECTED;
        // TODO: do refund
        payable(tokenOwner).transfer(timeToken.valueInWei);
    }

    function setFulfilled(uint256 tokenId) external {
        address tokenOwner = IMuseTime(museTimeNFT).ownerOf(tokenId);
        TimeToken memory timeToken = _timeTokens[tokenId];
        require(msg.sender == tokenOwner, "NOT_TOKEN_OWNER");
        require(timeToken.status == TimeTokenStatus.CONFIRMED, "WRONG_STATUS");
        _timeTokens[tokenId].status = TimeTokenStatus.FULFILLED;
        // TODO: do balance change
        _timeTroves[timeToken.topicOwner].balance += timeToken.valueInWei;
    }

    function withdrawFromTimeTrove() external {
        TimeTrove memory timeTrove = _timeTroves[msg.sender];
        require(timeTrove.balance > 0, "NO_BALANCE");
        _timeTroves[msg.sender].balance = 0;
        payable(msg.sender).transfer(timeTrove.balance);
    }

    /**
     *  @dev Render
     */

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        TimeToken memory timeToken = _timeTokens[tokenId];
        if (bytes(baseURI).length > 0 && bytes(timeToken.topicSlug).length > 0) {
            string memory suffix = string(abi.encodePacked(
                LibString.toString(tokenId),
                "/",
                timeToken.topicSlug,
                "/",
                timeToken.arId
            ));
            return string(abi.encodePacked(baseURI, suffix));
        } else {
            return "";
        }
    }

    /**
     * @dev Controller owner actions
     */

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }


    function setVerificationAddress(address verificationAddress_) external onlyOwner {
        verificationAddress = verificationAddress_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

}

interface IMuseTime {
    function mint(address to, uint256 tokenId) external;
    function ownerOf(uint256 id) external view returns (address owner);
}
