// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";

contract Counter is Owned {
    uint256 public number;

    constructor() Owned(msg.sender) {}

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
