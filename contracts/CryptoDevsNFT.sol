// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoDevsNFT is ERC721Enumerable {
    // initializing the ERC721 contract
    constructor() ERC721("CrytoDevs", "CD") {}

    function mint() public {
        _safeMint(msg.sender, totalSupply());
    }
}