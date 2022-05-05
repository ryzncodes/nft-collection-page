//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract NFTCollection is ERC721Enumerable, Ownable {

    //to compute {tokenURI}
    string _baseTokenURI;

    //price of one NFT
    uint256 public _price = 0.01 ether;

    //pause the contract in case of emergency
    bool public _paused;

    //max number of NFT
    uint256 public maxTokenIds = 20;

    //number of NFT minted
    uint256 public tokenIds;

    //whitelist contract instance
    IWhitelist whitelist;

    //boolean to keep track if the presale started or not
    bool public presaleStarted;

    //timestamp when presale ends
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    //ERC721 constructor takes in name & symbol of the token.
    //Constructor for this NFT takes baseURI to set _baseTokenURI for collection
    //Initializes an instance of whitelist interface

    constructor (string memory baseURI, address whitelistContract) ERC721("Raya Apes", "RA") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    //starting presale for whitelisted address
    //only owner of the contract can call this function.
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    //function to allow user mint 1 NFT during presale
    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
        //check if user is listed in the whitelistedAddresses
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum NFT supply.");
        require(msg.value >= _price, "Ether sent is not correct.");
        tokenIds += 1;
        //_safeMint functions the same way as _mint. 
        _safeMint(msg.sender, tokenIds);
    }

    //allow user to mint 1 NFT per tx after presale.
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "Presale has not ended.");
        require(tokenIds < maxTokenIds, "Exceeded maximum NFT supply.");
        require(msg.value >= _price,"Ether sent is not correct.");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

     //_baseURI overrides OZ ERC721, return an empty string for baseURI
     function _baseURI() internal view virtual override returns (string memory) {
         return _baseTokenURI;
     }

    //set if want to pause the contract or not.
     function setPaused(bool val) public onlyOwner {
         _paused = val;
     }

     //withdraw all ether in contract to contract owner.
     function withdraw() public onlyOwner {
         address _owner = owner();
         uint256 amount = address(this).balance;
         (bool sent, ) = _owner.call{value: amount}("");
         require(sent, "Failed to sent Ether");
     }

    //function to receive ether. msg.data must be empty/
     receive() external payable {}

     //when msg.data is not empty
     fallback() external payable {}
}