//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OptimizedMerkleDrop is ERC721 {
    /// ========= Immutable Storage =========
    bytes32 public immutable root;

    /// ========= Mutable Storage =========
    mapping(address => bool) hasClaimed;

    /// ========= Errors =========

    error AlreadyClaimed();
    error NotInMerkleTree();

    /// ========= Events =========

    event Claim(address indexed account, uint256 tokenId);

    /// ========= Constructor =========
    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleRoot
    ) ERC721(name, symbol) {
        root = merkleRoot;
    }

    /// ========= Functions =========

    function claim(
        address account,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external {
        // Throw error if address has already claimed the NFT
        if (hasClaimed[account]) {
            revert AlreadyClaimed();
        }

        bytes32 leaf = keccak256(abi.encodePacked(account, tokenId));
        if (!_verify(root, leaf, proof)) {
            revert NotInMerkleTree();
        }

        hasClaimed[account] = true;
        _safeMint(account, tokenId);

        emit Claim(account, tokenId);
    }

    function _verify(
        bytes32 _root,
        bytes32 leaf,
        bytes32[] calldata proof
    ) internal pure returns (bool valid) {
        assembly {
            let mem1 := mload(0x40)
            let mem2 := mload(0x20)
            let ptr := proof.offset

            for {
                let end := add(ptr, mul(0x20, proof.length))
            } lt(ptr, end) {
                ptr := add(ptr, 0x20)
            } {
                let node := calldataload(ptr)

                switch lt(leaf, node)
                case 1 {
                    mstore(mem1, leaf)
                    mstore(mem2, node)
                }
                default {
                    mstore(mem1, node)
                    mstore(mem2, leaf)
                }

                leaf := keccak256(mem1, 0x40)
            }

            valid := eq(_root, leaf)
        }
    }
}
