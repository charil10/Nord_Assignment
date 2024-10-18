// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BetSlipNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    constructor() ERC721("BetSlipNFT", "BSN") Ownable(msg.sender){
        tokenCounter = 0;
    }
    function mintBetSlip(address to, string memory tokenURI) external onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        tokenCounter++;
        return newTokenId;
    }
}
