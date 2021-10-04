// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoDogeNFT.sol";

interface ICryptoDogeController{
    function getClassInfo(uint256 _tokenId) external view returns(uint256);
}
contract MarketController is Ownable{
    using SafeERC20 for IERC20;

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
    }

    address public cryptoDogeNFT;
    address public token;
    address public cryptoDogeController;
    
    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function setCryptoDogeController(address _address) public onlyOwner{
        cryptoDogeController = _address;
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
        }
        return doges;
    }

    function getDogeOfSaleByOwner() public returns(Doge[] memory){
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
}