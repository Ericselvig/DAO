// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Interface for the FakeNFTMarketplace 
*/
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    function getPrice() external view returns (uint);

    /// @dev available() returns whether the given _tokenId NFT has already been purchased
    function available(uint _tokenId) external view returns (bool);

    /// function purchase() purchases an NFT from the FakeNFTMarketplace
    function purchase(uint _tokenId) external payable;
}

/**
 * Interface for the CryptoDevsNFT
 */
interface ICryptoDevsNFT {
    /// @dev balanceOf() returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    function balanceOf(address owner) external view returns (uint);

    /// @dev tokenOfOwnerByIndex() returns the tokenId at the given index for owner
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint);
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        // nftTokenId - The tokenId of the NFT to purchase from the fakeNFTMarketplace
        uint nftTokenId;

        // deadline - the UNIX timestamp unitl which the proposal is active.
        // proposal can be executed after this deadline if it has been passed.
        uint deadline;

        // yayVotes - number of yay votes for this proposal
        uint yayVotes;

        // nayVotes - number of nay votes for this proposal
        uint nayVotes;

        // executed - whether or not this proposal has been executed. cannot be true if deadline hasn't passed
        bool executed;

        // voters - a mapping of CryptoDevsNFT tokenIds to booleans indicating whether than nft has been used to cast a vote or not
        mapping(uint => bool) voters; 
    }

    // enum Vote to store types of vote
    enum Vote {
        YAY,
        NAY
    }

    // mapping of Ids to proposals
    mapping(uint => Proposal) public proposals;

    // numProposals - number of proposals that have been created
    uint public numProposals;

    // variables to store contracts
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    // constructor initializes the contract instances for FakeNFTMarketplace and CryptoDevsNFT
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    // modifier which only allows a function to be called by someone who owns atleast one CryptoDevsNFT
    modifier nftHolderOnly() {
        require (cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    // modifier which allows a function to be called if the given proposal's deadline
    // has not been exceeded yet
    modifier activeProposalOnly(uint proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // modifier which allows a function to be called if the given proposal's 
    // deadline has been exceeded and it hasn't been executed
    modifier inactiveProposalOnly(uint proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev createPropoal creates a proposal to buy an NFT from FakeNFTMarketplace
     * @param _nftTokenId - the tokenId of the NFT to be purchased from the FakeNFTMarketplace if proposal passes
     * @return Returns the proposal index for the newly created proposal 
    */
    function createProposal(uint _nftTokenId) 
        external
        nftHolderOnly
        returns (uint) 
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        // set the proposal deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    /**
     * @dev voteOnProposal allows a CryptoDevsNFT holder to cast a vote on an active proposal
     * @param proposalIndex - Index of the proposal
     * @param vote - type of vote they want to cast
     */
    function voteOnProposal(uint proposalIndex, Vote vote) 
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        
        uint voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint numVotes = 0;

        for (uint i = 0; i < voterNFTBalance;) {
            uint tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                ++numVotes;
                proposal.voters[tokenId] = true;
            }

            unchecked {
                ++i;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    /**
     * @dev executeProposal allows any cryptoDevsNFT holder to execute a proposal
     * after it's deadline has been exceeded
     * @param proposalIndex - index of the proposal to be executed
     */
    function executeProposal(uint proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex) 
    {
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner to withdraw ETH from the contract
    function withdrawEther() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FALIED_TO_WITHDRAW_ETHER");
    }
}