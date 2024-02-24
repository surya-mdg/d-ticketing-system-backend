// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Ticket is ERC721URIStorage{
    uint256 tokenId = 0;
    mapping(uint256 => Event) events;

    struct Event{
        string name;
        string location;
        uint256 time;
    }

    constructor() ERC721("DTicket","DTK") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        _setTokenURI()
        tokenId++;
    }


}