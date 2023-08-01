// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Extension of ERC721 to support delayed reveal of collection metadata
 * via a preset reveal timestamp.
 * {tokenURI} function calls return the placeholder URI until current block timestamp
 * exceeds the unix timestamp stored at `revealTimestamp`.
 * 
 * For {tokenURI} function calls made after `revealTimestamp` has been reached, 
 * the original URI of the token will be returned.
 */
abstract contract ERC721HiddenMetadataTimed is ERC721 {
    using Strings for uint256;

    // Errors
    error ERC721InvalidRevealTimestamp();
    error ERC721MetadataAlreadyRevealed();

    // Unix timestamp from which the real URI should be revealed
    uint256 public revealTimestamp;

    // The temporary URI to be returned until real URI has been revealed
    string private _placeholderURI;
    
    // Event emitted if reveal timestamp is updated
    event RevealTimestampUpdated(uint256 previousRevealTimestamp, uint256 newRevealTimestamp);

    modifier notRevealed() {
        _checkRevealed();
        _;
    }

    /**
     * @dev Initializes `revealTimestamp` and `_placeholderURI`.
     */
    constructor(uint256 _revealTimestamp, string memory placeholderURI_) {
        if(block.timestamp >= _revealTimestamp) revert ERC721InvalidRevealTimestamp();
        revealTimestamp = _revealTimestamp;
        _placeholderURI = placeholderURI_;
    }
    
    /**
     * @notice Update reveal timestamp.
     * @param _revealTimestamp New reveal timestamp.
     * 
     * Requirements:
     * 
     * - the caller must have `DEFAULT_ADMIN_ROLE` role.
     * - new reveal timestamp must be in the future.
     * - reveal timestamp must not have been reached.
     * 
     * Emits {RevealTimestampUpdated} event.
     */
    function setRevealTimestamp(uint256 _revealTimestamp) public virtual notRevealed {
        if(block.timestamp >= _revealTimestamp) revert ERC721InvalidRevealTimestamp();

        uint256 previousRevealTimestamp = revealTimestamp;
        revealTimestamp = _revealTimestamp;

        emit RevealTimestampUpdated(previousRevealTimestamp, _revealTimestamp);
    }

    /**
     * @notice Update placeholder URI.
     * @param placeholderURI_ New placeholder URI to be used.
     * 
     * Requirements:
     * 
     * - the caller must have `DEFAULT_ADMIN_ROLE` role.
     * - reveal timestamp must not have been reached.
     */
    function setPlaceholderURI(string calldata placeholderURI_) public virtual notRevealed {
        _placeholderURI = placeholderURI_;
    }

    /**
     * @notice Returns if reveal timestamp has been reached.
     */
    function revealed() public view virtual returns (bool) {
        return block.timestamp >= revealTimestamp;
    }

    /**
     * @dev Override to return placeholder URI until reveal timestamp has been reached.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        
        if(!revealed()) return _placeholderURI;

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Reverts if `revealTimestamp` has been reached.
     */
    function _checkRevealed() internal view virtual {
        if(revealed()) revert ERC721MetadataAlreadyRevealed();
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
