// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ECDSA.sol";

library SignatureVerification {
    using ECDSA for bytes32;

    function requireValidSignature(
        bytes memory data,
        bytes memory signature,
        address signerAddress
    ) internal pure {
        require(signerAddress != address(0), "SIGNER_NOT_INITIALIZED");
        require(
            keccak256(data).toEthSignedMessageHash().recover(signature) == signerAddress,
            "INVALID_SIGNATURE"
        );
    }
}
