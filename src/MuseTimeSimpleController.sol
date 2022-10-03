// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "./interfaces/IERC20.sol";


contract MuseTimeSimpleController is Owned {

    address public immutable museTimeNFT;
    string public baseURI;
    uint256 public mintIndex;

    /* variables end */

    constructor(
        address museTimeNFT_,
        string memory baseURI_
    ) Owned(msg.sender) {
        museTimeNFT = museTimeNFT_;
        baseURI = baseURI_;
    }

    /**
     *  @dev mint logic
     */

    function mint() external payable {
        require(msg.value >= 1 ether, "INSUFFICIENT_VALUE");
        IMuseTime(museTimeNFT).mint(msg.sender, ++mintIndex);
    }

    /**
     *  @dev render logic
     */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, LibString.toString(tokenId))) : "";
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
