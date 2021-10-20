// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDogeNFT.sol";
import "./IMagicStoneNFT.sol";

interface ICryptoDogeController{
    function getClassInfo(uint256 _tokenId) external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
    function setStoneTime(uint256 _tokenId) external view returns(uint256);
    function cooldownTime() external view returns(uint256);
    function stoneInfo(uint256 _tokenId) external view returns(uint256);
}

interface IMagicStoneController{
    function stoneDogeInfo(uint256 _stoneId) external view returns(uint256);
    function dogeStoneInfo(uint256 _dogeId) external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
}
contract MarketController is Ownable{

    struct Doge{
        uint256 _tokenId;
        uint256 _generation;
        uint256 _tribe;
        uint256 _exp;
        uint256 _dna;
        uint256 _farmTime;
        uint256 _bornTime;
        uint256 _rare;
        uint256 _level;
        bool _isEvolved;
        uint256 _salePrice;
        address _owner;
        uint256 _classInfo;
        uint256 _availableBattleTime;
        uint256 _stoneInfo;
    }

    struct Stone{
        uint256 _tokenId;
        uint256 _dogeId;
    }

    address public cryptoDogeNFT;
    address public cryptoDogeController;
    address public magicStoneNFT;
    address public magicStoneController;
    
    constructor (){
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        cryptoDogeController = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneController = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function setCryptoDogeController(address _address) public onlyOwner{
        cryptoDogeController = _address;
    }

    function setMagicStoneNFT(address _nftAddress) public onlyOwner{
        magicStoneNFT = _nftAddress;
    }

    function setMagicStoneController(address _address) public onlyOwner{
        magicStoneController = _address;
    }

    function getDogesInfo(uint256[] memory ids) public view returns(Doge[] memory){
        uint256 totalDoges = ids.length;
        Doge[] memory doges= new Doge[](totalDoges);
        for(uint256 i = 0; i < totalDoges; i ++){
            doges[i]._tokenId = ids[i];
            (uint256 _generation, uint256 _tribe, uint256 _exp, uint256 _dna, uint256 _farmTime, uint256 _bornTime) = ICryptoDogeNFT(cryptoDogeNFT).getdoger(ids[i]);
            doges[i]._generation = _generation;
            doges[i]._tribe = _tribe;
            doges[i]._exp = _exp;
            doges[i]._dna = _dna;
            doges[i]._farmTime = _farmTime;
            doges[i]._bornTime = _bornTime;
            doges[i]._rare = ICryptoDogeNFT(cryptoDogeNFT).getRare(ids[i]);
            doges[i]._level = ICryptoDogeNFT(cryptoDogeNFT).dogerLevel(ids[i]);
            doges[i]._isEvolved = ICryptoDogeNFT(cryptoDogeNFT).isEvolved(ids[i]);
            (, address owner, uint256 price) = ICryptoDogeNFT(cryptoDogeNFT).getSale(ids[i]);
            if(owner != address(0))
                doges[i]._owner = owner;
            else
                doges[i]._owner = ICryptoDogeNFT(cryptoDogeNFT).ownerOf(ids[i]);
            doges[i]._salePrice = price;
            doges[i]._classInfo = ICryptoDogeController(cryptoDogeController).getClassInfo(ids[i]);

            doges[i]._stoneInfo = IMagicStoneController(magicStoneController).dogeStoneInfo(ids[i]);
            if(doges[i]._stoneInfo == 0)
                doges[i]._availableBattleTime = ICryptoDogeController(cryptoDogeController).battleTime(ids[i]) + ICryptoDogeController(cryptoDogeController).cooldownTime();
            else
                doges[i]._availableBattleTime = IMagicStoneController(magicStoneController).battleTime(ids[i]) + ICryptoDogeController(cryptoDogeController).cooldownTime();
            
        }
        return doges;
    }

    function getDogeOfSaleByOwner() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).orders(msg.sender);
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenSaleOfOwnerByIndex(msg.sender, i);
        }
        return getDogesInfo(ids);
    }

    function getDogeOfSale() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).marketsSize();
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenSaleByIndex(i);
        }
        return getDogesInfo(ids);
    }
    
    function getDogeByOwner() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getDogesInfo(ids);
    }

    function getStonesInfo(uint256[] memory ids) public view returns(Stone[] memory){
        uint256 totalStones = ids.length;
        Stone[] memory stones= new Stone[](totalStones);
        for(uint256 i = 0; i < totalStones; i ++){
            stones[i]._tokenId = ids[i];
            stones[i]._dogeId = IMagicStoneController(magicStoneController).stoneDogeInfo(ids[i]);
        }
        return stones;
    }

    function getStoneByOwner() public view returns(Stone[] memory){
        uint256 totalStones = IMagicStoneNFT(magicStoneNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalStones);
        uint256 i = 0;
        for(; i < totalStones; i ++){
            ids[i] = IMagicStoneNFT(magicStoneNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getStonesInfo(ids);
    }
}