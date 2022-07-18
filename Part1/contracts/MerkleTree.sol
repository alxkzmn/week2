//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 levels = 3;

    constructor() {
        for (uint256 i = 0; i < levels; i++) {
            for (uint256 j = 0; j < 2**(levels - i); j++) {
                if (i == 0) {
                    hashes.push(0);
                } else {
                    uint256 hash = PoseidonT3.poseidon(
                        [hashes[2 * i], hashes[2 * i + 1]]
                    );
                    hashes.push(hash);
                }
            }
        }
        root = hashes[hashes.length - 1];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        hashes[index] = hashedLeaf;

        for (uint256 i = 0; i < levels - 1; i++) {
            hashes[8 + 4 * i + index / (2 + 2 * i)] = PoseidonT3.poseidon(
                (index / (1 + i)) % 2 == 0
                    ? [
                        hashes[8 * i + index / (1 + i)],
                        hashes[8 * i + index / (1 + i) + 1]
                    ]
                    : [
                        hashes[8 * i + index / (1 + i) - 1],
                        hashes[8 * i + index / (1 + i)]
                    ]
            );
        }

        root = PoseidonT3.poseidon(
            [hashes[hashes.length - 2], hashes[hashes.length - 1]]
        );

        index++;
        return root;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        return verifyProof(a, b, c, input);
    }
}
