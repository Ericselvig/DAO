// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FakeNFTMarketplace {
    /// @dev maintain a mapping of Fake tokenID to owner address
    mapping (uint => address) public tokens;

    /// set the purchase price for each NFT
    uint nftPrice = 0.1 ether;

    /// @dev purchase accepts ETH and marks the owner of the given tokenId as the address of the caller
    /// @param _tokenId - the fake NFT token Id to purchase
    function purchase(uint _tokenId) external payable {
        require (msg.value == nftPrice, "This NFT costs 0.1 Ether");
        tokens[_tokenId] = msg.sender;
    } 

    /// @dev getPrice() returns the price of one NFT
    function getPrice() external view returns (uint) {
        return nftPrice;
    } 

    /// @dev available() checks whether the given NFT is available for sale or not
    /// @param _tokenId - the fake NFT token Id to check for 
    function available(uint _tokenId) external view returns (bool) {
        return tokens[_tokenId] == address(0);
    }
}