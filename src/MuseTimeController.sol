// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "solmate/utils/LibString.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SignatureVerification.sol";

contract MuseTimeController is OwnableUpgradeable {

    struct TimeTrove {
        bytes32 arOwnerAddress;
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
        bytes32 profileArId;
        bytes32 topicsArId;
        bytes32 topicId;
        address topicOwner;
        TimeTokenStatus status;
    }

    address public museTimeNFT;
    address public paramsSigner;

    string public baseURI;
    uint256 public mintIndex;

    /**
     * @dev Key(uint256) mapping to a claimed key.
     * Used to prevent address from rebroadcasting mint transactions
     */
    mapping(uint256 => bool) private _claimedMintKeys;
    mapping(address => TimeTrove) private _timeTrovesLegacy;  // deprecated, but keep the storage slot

    mapping(address => TimeTrove) private _timeTroves;
    mapping(uint256 => TimeToken) private _timeTokens;

    /* variables end */

    event TimeTroveCreated(address indexed topicOwner);
    event TimeTokenMinted(
        address indexed topicOwner, bytes32 indexed topicId,
        address indexed tokenOwner, uint256 tokenId);

    /* events end */

    function initialize(
        address museTimeNFT_,
        string memory baseURI_,
        address paramsSigner_
    ) initializer public {
        __Ownable_init();
        museTimeNFT = museTimeNFT_;
        baseURI = baseURI_;
        paramsSigner = paramsSigner_;
    }

    /**
     *  @dev TimeTrove
     */

    function createTimeTrove(bytes32 arOwnerAddress, bytes memory signature) external {
        SignatureVerification.requireValidSignature(
            abi.encodePacked(this, msg.sender, arOwnerAddress),
            signature,
            paramsSigner
        );
        _timeTroves[msg.sender] = TimeTrove(arOwnerAddress, 0);
        emit TimeTroveCreated(msg.sender);
    }

    function timeTroveOf(address topicOwner) external view returns (TimeTrove memory) {
        return _timeTroves[topicOwner];
    }

    /**
     *  @dev TimeToken
     */

    function mintTimeToken(
        uint256 mintKey,
        uint256 valueInWei,
        bytes32 profileArId,
        bytes32 topicsArId,
        bytes32 topicId,
        address topicOwner,
        bytes memory signature
    ) external payable {
        require(_claimedMintKeys[mintKey] == false, "MINT_KEY_CLAIMED");
        require(valueInWei == msg.value, "Incorrect ether value");
        SignatureVerification.requireValidSignature(
            abi.encodePacked(this, msg.sender, mintKey, valueInWei, profileArId, topicsArId, topicId, topicOwner),
            signature,
            paramsSigner
        );
        _claimedMintKeys[mintKey] = true;
        mintIndex += 1;
        _timeTokens[mintIndex] = TimeToken(
            valueInWei, profileArId, topicsArId, topicId, topicOwner, TimeTokenStatus.PENDING);
        IMuseTime(museTimeNFT).mint(msg.sender, mintIndex);
        emit TimeTokenMinted(topicOwner, topicId, msg.sender, mintIndex);
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
        // do refund
        payable(tokenOwner).transfer(timeToken.valueInWei);
    }

    function setFulfilled(uint256 tokenId) external {
        address tokenOwner = IMuseTime(museTimeNFT).ownerOf(tokenId);
        TimeToken memory timeToken = _timeTokens[tokenId];
        require(msg.sender == tokenOwner, "NOT_TOKEN_OWNER");
        require(timeToken.status == TimeTokenStatus.CONFIRMED, "WRONG_STATUS");
        _timeTokens[tokenId].status = TimeTokenStatus.FULFILLED;
        // change balance
        _timeTroves[timeToken.topicOwner].balance += timeToken.valueInWei;
    }

    function withdrawFromTimeTrove() external {
        uint256 balance = _timeTroves[msg.sender].balance;
        require(balance > 0, "NO_BALANCE");
        _timeTroves[msg.sender].balance = 0;
        payable(msg.sender).transfer(balance);
    }

    /**
     *  @dev Render
     */

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        // 只需要 tokenid 就行, timetoken/xxx/xxx 接口可以通过tokenid取到所有信息
        TimeToken memory timeToken = _timeTokens[tokenId];
        if (bytes(baseURI).length > 0 && timeToken.topicId > 0) {
            return string(abi.encodePacked(baseURI, LibString.toString(tokenId)));
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


    function setParamsSigner(address paramsSigner_) external onlyOwner {
        paramsSigner = paramsSigner_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

}

interface IMuseTime {
    function mint(address to, uint256 tokenId) external;
    function ownerOf(uint256 id) external view returns (address owner);
}
