// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721.sol";
import "./ManagerInterface.sol";

contract MagicStoneNFT is ERC721{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using EnumerableSet for EnumerableSet.UintSet;

    event BuyStone(uint256 indexed tokenId, address buyer);

    mapping(address => EnumerableSet.UintSet) private stones;

    // constructor() ERC721("CryptoDoge Magic Stone", "MagicStone") {}
    constructor(
        string memory _name,
        string memory _symbol,
        address _manager
    ) ERC721(_name, _symbol, _manager) {}

    modifier onlySpawner() {
        require(manager.evolvers(msg.sender), "require Spawner.");
        _;
    }

    function createStone(address receiver) external onlySpawner{
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        stones[receiver].add(newItemId);
        emit BuyStone(newItemId, receiver);
    }

    function burn(uint256 _tokenId, address _address) external onlySpawner {
        _burn(_tokenId);
        stones[_address].remove(_tokenId);
    }

    function priceStone() public view returns (uint256) {
        return manager.priceStone();
    }
}
