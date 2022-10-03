// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SignatureVerification.sol";

contract MuseTimeController is Owned {

    address public immutable museTimeNFT;
    address public verificationAddress;

    string public baseURI;
    uint256 public mintIndex;

    mapping(uint256 => string) public slugs;

    /* variables end */

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
     *  @dev mint logic
     */

    function setVerificationAddress(address verificationAddress_) external onlyOwner {
        verificationAddress = verificationAddress_;
    }

    function mintWithSignature(
        uint256 valueInWei,
        address topicOwner,
        string memory slug,
        bytes memory signature
    ) external payable {
        require(valueInWei == msg.value, "Incorrect ether value");

        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, valueInWei, topicOwner, slug, this),
            signature,
            verificationAddress
        );

        mintIndex += 1;
        slugs[mintIndex] = slug;

        IMuseTime(museTimeNFT).mint(msg.sender, mintIndex);
    }

    /**
     *  @dev render logic
     */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory slug = slugs[tokenId];
        if (bytes(baseURI).length > 0 && bytes(slug).length > 0) {
            return string(abi.encodePacked(baseURI, slug));
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
