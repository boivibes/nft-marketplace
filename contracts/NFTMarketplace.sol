// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 private _tokenIds;
    uint256 private _itemsSold;
    uint256 public listingFee = 0.01 ether;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) public marketItems;

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event MarketItemSold(
        uint256 indexed tokenId,
        address buyer,
        uint256 price
    );

    constructor() ERC721("NFTMarketplace", "NFTM") Ownable(msg.sender) {}

    function mintAndList(string memory tokenURI, uint256 price)
        external payable nonReentrant returns (uint256) {
        require(msg.value == listingFee, "Must pay listing fee");
        require(price > 0, "Price must be greater than 0");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        marketItems[newTokenId] = MarketItem(
            newTokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), newTokenId);

        emit MarketItemCreated(newTokenId, msg.sender, address(this), price, false);
        return newTokenId;
    }

    function buyNFT(uint256 tokenId) external payable nonReentrant {
        MarketItem storage item = marketItems[tokenId];
        require(msg.value == item.price, "Incorrect price");
        require(!item.sold, "Item already sold");

        item.seller.transfer(msg.value);
        _transfer(address(this), msg.sender, tokenId);
        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold++;

        emit MarketItemSold(tokenId, msg.sender, msg.value);
    }

    function getUnsoldItems() external view returns (MarketItem[] memory) {
        uint256 unsoldCount = _tokenIds - _itemsSold;
        MarketItem[] memory items = new MarketItem[](unsoldCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _tokenIds; i++) {
            if (!marketItems[i].sold) {
                items[index] = marketItems[i];
                index++;
            }
        }
        return items;
    }

    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function updateListingFee(uint256 _fee) external onlyOwner {
        listingFee = _fee;
    }
}
