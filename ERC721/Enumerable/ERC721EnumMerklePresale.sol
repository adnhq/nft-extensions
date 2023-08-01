// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20; 

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Extension of ERC721 to support allowlist minting via Merkle Tree
 */
abstract contract ERC721EnumMerklePresale is ERC721Enumerable {

    // Errors
    error ERC721InvalidMerkleProof();
    error ERC721PresaleMintLimitExceeded();
    error ERC721PresaleEnded();

    // Maximum amount that can be minted by an allowed address
    uint256 public presaleMintLimit;

    // Merkle root to verify whitelisted addresses
    bytes32 public merkleRoot;

    // Boolean to indicate whether presale is on
    bool public presale = true;

    // Mapping to keep track of amounts minted by allowed addresses during presale
    mapping(address => uint256) public presaleMints; 

    // Modifier to check whether presale is active
    modifier presaleOn() {
        _checkPresale();
        _;
    }

    /**
     * @dev Initializes `merkleRoot` and `presaleMintLimit`
     */
    constructor(bytes32 _merkleRoot, uint256 _presaleMintLimit) {
        merkleRoot = _merkleRoot;
        presaleMintLimit = _presaleMintLimit;
    }

    /**
     * @dev Updates value for `merkleRoot`.
     * 
     * Requirements:
     * 
     * - presale must be on.
     * NOTE: Access should be controlled.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public virtual presaleOn {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Ends presale phase.
     * 
     * Sets `presale` to false.
     * 
     * Requirements:
     * 
     * - presale must be on.
     * NOTE: Access should be controlled.
     */
    function endPresale() public virtual presaleOn {
        presale = false;
    }

    /**
     * @dev Mints `amount` tokens to caller.
     * @param proof Merkle proof to verify caller.
     * @param amount Amount of tokens to mint.
     * 
     * Requirements:
     * 
     * - presale must be on.
     * - the caller must be on allowlist.
     * - the caller must not have claimed mint already.
     */
    function _mintPresale(bytes32[] calldata proof, uint256 amount) internal virtual presaleOn { 
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        if(!MerkleProof.verifyCalldata(proof, merkleRoot, leaf)) revert ERC721InvalidMerkleProof();
    
        unchecked {
            presaleMints[msg.sender] += amount;
        }

        if(presaleMints[msg.sender] > presaleMintLimit) revert ERC721PresaleMintLimitExceeded();

        uint256 totalSupply_ = totalSupply();
        
        unchecked {
            for(uint256 i; i < amount; ++i) 
                _safeMint(msg.sender, totalSupply_ + i);
        }
    }

    /**
     * @dev Reverts if `presale` is false.
     */
    function _checkPresale() private view {
        if(!presale) revert ERC721PresaleEnded();
    }
}
