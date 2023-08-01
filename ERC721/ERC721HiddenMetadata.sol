// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Extension of ERC721 to support delayed reveal of collection metadata.
 * {tokenURI} function calls return the placeholder URI until the {reveal} function 
 * has been called and as such `revealed` has been set to true.
 * For subsequent {tokenURI} function calls, the original URI of the token is returned.
 */
abstract contract ERC721HiddenMetadata is ERC721 {
    using Strings for uint256;
    
    // Errors
    error ERC721MetadataAlreadyRevealed();
    
    // The uri to be returned until real URI has been revealed
    string private _placeholderURI;

    // Boolean to indicate whether real URI of collection has been revealed
    bool public revealed;

    modifier notRevealed() {
        _checkRevealed();
        _;
    }

    /**
     * @dev Initializes `_placeholderURI`.
     */
    constructor(string memory placeholderURI_) {
        _placeholderURI = placeholderURI_;
    }

    /**
     * @notice Reveal original URI for collection.
     * 
     * Requirements:
     * 
     * - must not have been revealed already.
     */
    function reveal() public virtual notRevealed {
        revealed = true;
    }
    
    /**
     * @notice Update placeholder URI.
     * @param placeholderURI_ New placeholder URI to be used.
     * 
     * Requirements:
     * 
     * - must not have been revealed already.
     */
    function setPlaceholderURI(string calldata placeholderURI_) public virtual notRevealed {
        _placeholderURI = placeholderURI_;
    }

    /**
     * @dev Override to return placeholder URI until reveal function has been called.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        
        if(!revealed) return _placeholderURI;

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Reverts if `revealed` is true.
     */
    function _checkRevealed() internal view virtual {
        if(revealed) revert ERC721MetadataAlreadyRevealed();
    }

    // The following functions are overrides required by Solidity.
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
