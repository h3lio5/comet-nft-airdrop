// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CometMerkleDrop is ERC721 {
    bytes32 public immutable root;

    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleRoot
    ) ERC721(name, symbol) {
        root = merkleRoot;
    }

    function claim(
        address account,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external {
        require(
            _verify(_leaf(account, tokenId), proof),
            "Invalid merkle proof"
        );
        _safeMint(account, tokenId);
    }

    function _leaf(address account, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
