// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SignatureVerification.sol";

contract MuseTimeController is Owned {

    address public immutable museTimeNFT;
    address public verificationAddress;

    string public baseURI;
    uint256 public mintIndex;

    struct TimeTrove {
        string addressAR;
        uint256 balance;
    }

    mapping(address => TimeTrove) internal _timeTroves;

    // tokenId to slug
    mapping(uint256 => string) internal _topicSlugOf;
    // tokenId to topic owner
    mapping(uint256 => address) internal _topicOwnerOf;

    /* variables end */

    event TimeTroveCreated(address indexed _topicOwner);

    /* events end */

    constructor(
        address museTimeNFT_,
        string memory baseURI_,
        address verificationAddress_
    ) Owned(msg.sender) {
        museTimeNFT = museTimeNFT_;
        baseURI = baseURI_;
        verificationAddress = verificationAddress_;
    }

    /**
     *  @dev create TimeTrove
     */

    function createTimeTrove(string memory addressAR, bytes memory signature) external {
        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, addressAR, this),
            signature,
            verificationAddress
        );
        TimeTrove memory timeTrove = TimeTrove(addressAR, 0);
        _timeTroves[msg.sender] = timeTrove;
        emit TimeTroveCreated(msg.sender);
    }

    function timeTroveOf(address topicOwner) external view returns (TimeTrove memory) {
        return _timeTroves[topicOwner];
    }

    /**
     *  @dev mint logic
     */

    function setVerificationAddress(address verificationAddress_) external onlyOwner {
        verificationAddress = verificationAddress_;
    }

    function mint(
        uint256 valueInWei,
        address topicOwner,
        string memory topicSlug,
        bytes memory signature
    ) external payable {
        require(valueInWei == msg.value, "Incorrect ether value");
        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, valueInWei, topicOwner, topicSlug, this),
            signature,
            verificationAddress
        );
        mintIndex += 1;
        _topicSlugOf[mintIndex] = topicSlug;
        _topicOwnerOf[mintIndex] = topicOwner;
        IMuseTime(museTimeNFT).mint(msg.sender, mintIndex);
    }

    /**
     *  @dev render logic
     */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory slug = _topicSlugOf[tokenId];
        if (bytes(baseURI).length > 0 && bytes(slug).length > 0) {
            return string(abi.encodePacked(baseURI, LibString.toString(tokenId), slug));
        } else {
            return "";
        }
    }

    /**
     * @dev Receive and withdraw assets
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

}

interface IMuseTime {
    function mint(address to, uint256 tokenId) external;
}
