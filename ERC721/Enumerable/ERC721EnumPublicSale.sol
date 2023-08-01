// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20; 

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev Extension of ERC721 to support public and reserve minting.
 */
abstract contract ERC721EnumPublicSale is ERC721Enumerable {

    // Errors
    error ERC721IncorrectPrice();
    error ERC721MintLimitExceeded();
    error ERC721AmountExceedsReserve();
    error ERC721FundTransferFailed();

    // Price per mint
    uint256 public price;
    
    // Mint limit per transaction
    uint256 public mintLimit;
    
    // Amount to be reserved for team
    uint256 public reserve;

    /**
     * Initializes `price`, `mintLimit` and `reserveMint`
     */
    constructor(uint256 _price, uint256 _mintLimit, uint256 _reserve) {
        price = _price;
        mintLimit = _mintLimit;
        reserve = _reserve;
    }

    /**
     * @notice Updates price per mint.
     * @param _price New price per mint.
     * NOTE: Access should be controlled.
     */
    function setPrice(uint256 _price) public virtual {
        price = _price;
    }
    
    /**
     * @notice Update mint limit per transaction.
     * @param _mintLimit New mint limit
     * NOTE: Access should be controlled.
     */
    function setMintLimit(uint256 _mintLimit) public virtual {
        mintLimit = _mintLimit;
    }

    /**
     * @dev Mints `amount` tokens to `to`.
     * 
     * Requirements:
     * 
     * - appropriate price must be sent with tx. 
     * - `amount` should not exceed mint limit per tx.
     *
     */
    function _mintPublic(address to, uint256 amount) internal virtual {
        if(msg.value != price * amount) revert ERC721IncorrectPrice();
        if(amount > mintLimit) revert ERC721MintLimitExceeded();

        uint256 totalSupply_ = totalSupply();

        unchecked {
            for(uint256 i; i < amount; ++i)
                _safeMint(to, totalSupply_ + i);
        }
    }

    /**
     * @dev Mints `amount` tokens to `to`.
     * Should be used to mint reserve tokens for team.
     * 
     * Requirements:
     * 
     * - `amount` should not exceed `reserve`.
     */
    function _mintReserve(address to, uint256 amount) internal virtual {
        if(amount > reserve) revert ERC721AmountExceedsReserve();

        unchecked {
            reserve -= amount;
        }

        uint256 totalSupply_ = totalSupply();

        unchecked {
            for(uint256 i; i < amount; ++i) 
                _safeMint(to, totalSupply_ + i);
        }
    }
    
    /**
     * @dev Transfers Eth in contract to a recipient.
     * Should be overriden and used with controlled access.
     * 
     */
    function _collectFunds(address to, uint256 amount) internal virtual {
        bool success;
    
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if(!success) revert ERC721FundTransferFailed();
    }

    // The following functions are overrides required by Solidity.
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
