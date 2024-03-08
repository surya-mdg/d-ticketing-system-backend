// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Ticket is ERC721URIStorage{
    uint256 tokenId = 0;
    mapping(uint256 => Event) events;
    mapping(uint256 => Metadata) meta;

    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event TokenSold(address indexed buyer, uint256 indexed tokenId);

    struct Event{
        address payable owner;
        uint256 time;
        uint256 transferDeadline;
        uint256 cost;
        uint256 sellingPrice;
        bool isSellable;
        string uri;
    }

    struct Metadata{
        address payable owner;
        string name;
        string time;
        string location;
        string seat;
    }

    constructor() ERC721("DTicket","DTK") {}

    modifier onlyTokenOwner(uint256 _tokenId){
        require(msg.sender == ERC721.ownerOf(_tokenId), "Error: Function caller not the token owner");
        _;
    }

    modifier tokenExists(uint256 _tokenId){
        require(_tokenId < tokenId, "Error: Token ID does not exist");
        _;
    }

    function mint(string memory _name, string memory _time, string memory _loc, string memory _seat, uint256 _eventTime, uint8 _transferType, uint256 _deadlineTime, uint256 _ticketCost) public payable{
        require(_eventTime > block.timestamp, "Mint Error: Event time needs to be greater than current time");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, "");

        if(_transferType == 0)
            events[tokenId] = Event(payable(msg.sender), _eventTime, _eventTime, _ticketCost, _ticketCost, false, "");
        else if(_transferType == 1)
            events[tokenId] = Event(payable(msg.sender), _eventTime, _eventTime - _deadlineTime, _ticketCost, _ticketCost, false, "");
        else
            events[tokenId] = Event(payable(msg.sender), _eventTime, 0, _ticketCost, _ticketCost, false, "");
        
        meta[tokenId] = Metadata(payable(msg.sender), _name, _time, _loc, _seat);

        emit TokenMinted(msg.sender, tokenId);
        tokenId++;
    }

    function transfer(uint256 _tokenId, address _to) tokenExists(_tokenId) tokenExists(_tokenId) onlyTokenOwner(_tokenId) public{
        require(block.timestamp < events[_tokenId].transferDeadline, "Transfer Error: Cannot transfer token after deadline");

        _transfer(msg.sender, _to, _tokenId);
        emit TokenTransferred(msg.sender, _to, _tokenId);
    }

    function verify(uint256 _tokenId, address _owner) tokenExists(_tokenId) view public returns(bool){
        return ERC721.ownerOf(_tokenId) == _owner;
    }

    function sell(uint256 _sellingPrice, uint256 _tokenId) tokenExists(_tokenId) onlyTokenOwner(_tokenId) public {
        require(_sellingPrice <= events[_tokenId].cost, "Sell Error: Selling price cannot be greater than initial cost");
        require(block.timestamp <= events[_tokenId].transferDeadline, "Sell Error: Cannot transfer token after deadline");

        events[_tokenId].sellingPrice = _sellingPrice;
        events[_tokenId].isSellable = true;
    }

    function revertSell(uint256 _tokenId) tokenExists(_tokenId) onlyTokenOwner(_tokenId) external {
        events[_tokenId].isSellable = false;
    } 

    function buy(uint256 _tokenId) tokenExists(_tokenId) external payable{
        require(events[_tokenId].isSellable, "Buy Error: Token not for sale");
        require(block.timestamp <= events[_tokenId].transferDeadline, "Buy Error: Cannot transfer token after deadline");
        require(msg.value >= events[_tokenId].sellingPrice, "Buy Error: Insuffiecient amount sent");

        events[_tokenId].isSellable = false;
        _burn(_tokenId);
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, events[_tokenId].uri);
        events[_tokenId].owner.transfer(events[_tokenId].sellingPrice);
        emit TokenSold(msg.sender, _tokenId);
    }

    function getTokenId() view public returns(uint256){
        return tokenId;
    }

    function getMetadata(uint256 _tokenId) tokenExists(_tokenId) view public returns(Metadata memory){
        Metadata memory _meta = Metadata(events[_tokenId].owner, meta[_tokenId].name, meta[_tokenId].time, meta[_tokenId].location, meta[_tokenId].seat);
        return _meta;
    }
}