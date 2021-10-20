// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDogeNFT.sol";
import "./ManagerInterface.sol";

contract SendCryptoDoge is Ownable{
    using SafeMath for uint256;

    address public cryptoDogeNFT;
    ManagerInterface manager;

    constructor (){
        cryptoDogeNFT = address(0x643a211d36B745864D89EBc1913140CEDA7d1323);
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function createDoge(address receiver) public onlyOwner{
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        manager = ManagerInterface(cryptoDoge.manager());
        require(cryptoDoge.totalSupply() <= manager.nftMaxSize(), "Sold Out");
        uint8 tribe = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, receiver, cryptoDoge.balanceOf(receiver)))) % 4);
        uint8[] memory tribes = new uint8[](1);
        tribes[0] = tribe;
        cryptoDoge.layDoge(receiver, tribes);
    }
}