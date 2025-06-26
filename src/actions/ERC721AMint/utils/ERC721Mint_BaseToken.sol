// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721A} from "@erc721a/ERC721A.sol";
import {IERC2981, IERC165} from "@openzeppelin-4.8.0/interfaces/IERC2981.sol";

uint256 constant MAX_ROYALTY = 10_000;

/**
 * @title ERC721Mint_BaseToken
 * @notice Base ERC721 token for ERC721Mint onchain action.
 */
contract ERC721Mint_BaseToken is ERC721A, IERC2981 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotMinter();
    error MaxSupplyExceeded();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable minter;

    uint256 public maxSupply;
    address public royaltyReceiver;
    uint256 public royaltyFraction;
    string public baseURI_;
    string public tokenURI_;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint256 royaltyFraction_,
        string memory baseURI__,
        string memory tokenURI__
    ) ERC721A(name_, symbol_) {
        minter = msg.sender;

        _setMaxSupply(maxSupply_);
        royaltyReceiver = royaltyReceiver_;
        royaltyFraction = royaltyFraction_;
        baseURI_ = baseURI__;
        tokenURI_ = tokenURI__;
    }

    /*//////////////////////////////////////////////////////////////
                            ACTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) public {
        if (msg.sender != minter) revert NotMinter();
        _mint(to, amount);

        if (totalSupply() > maxSupply) revert MaxSupplyExceeded();
    }

    function setParams(
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint256 royaltyFraction_,
        string memory baseURI__,
        string memory tokenURI__
    ) external {
        if (msg.sender != minter) revert NotMinter();

        royaltyReceiver = royaltyReceiver_;
        royaltyFraction = royaltyFraction_;
        baseURI_ = baseURI__;
        tokenURI_ = tokenURI__;
        _setMaxSupply(maxSupply_);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721A FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ERC721A
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : tokenURI_;
    }

    /**
     * @inheritdoc ERC721A
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
        // return the receiver from storage
        _receiver = royaltyReceiver;

        // calculate and return the _royaltyAmount
        _royaltyAmount = (salePrice * royaltyFraction) / MAX_ROYALTY;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setMaxSupply(uint256 maxSupply_) internal {
        maxSupply = maxSupply_ == 0 ? type(uint256).max : maxSupply_;
    }
}
